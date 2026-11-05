-- =============================================================================
-- INSTITUTO HORIZONTE LIVRE (IHL CIRCULAR) - MOGI DAS CRUZES / SP
-- ESQUEMA RELACIONAL POSTGRESQL / SUPABASE
-- =============================================================================

-- Habilita extensão para UUIDs se necessário
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. TIPOS ENUMERADOS
-- -----------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE user_role_enum AS ENUM ('comum', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE product_category_enum AS ENUM ('artesanato', 'brecho', 'materiais');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE product_status_enum AS ENUM ('available', 'reserved', 'sold');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE donation_category_enum AS ENUM ('brecho', 'materiais');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE donation_status_enum AS ENUM ('scheduled', 'received', 'cancelled');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- -----------------------------------------------------------------------------
-- 2. TABELA DE USUÁRIOS (GOVERNANÇA LGPD)
-- Coleta estritamente restrita a Nome, E-mail e Celular
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(30) NOT NULL,
    role user_role_enum NOT NULL DEFAULT 'comum',
    terms_accepted BOOLEAN NOT NULL DEFAULT FALSE,
    terms_accepted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT check_lgpd_terms_accepted CHECK (terms_accepted = TRUE)
);

-- -----------------------------------------------------------------------------
-- 3. TABELA DE PRODUTOS & ESTOQUE CIRCULAR
-- Regra de Negócio 2: Teto de R$ 50,00 nos Artesanatos PcD e autor obrigatório
-- Regra de Negócio 1: Cronômetro de Reserva de 168 Horas (7 Dias)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    id VARCHAR(64) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category product_category_enum NOT NULL,
    price NUMERIC(10, 2) NOT NULL CHECK (price > 0),
    image_url TEXT NOT NULL,
    author_pcd VARCHAR(255),
    status product_status_enum NOT NULL DEFAULT 'available',
    
    -- Controle de Reserva Presencial (168h / 7 dias)
    reserved_by_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    reserved_by_name VARCHAR(255),
    reserved_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Baixa Presencial no Balcão
    sold_at TIMESTAMP WITH TIME ZONE,
    buyer_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,

    -- CONSTRAINT ESTRITA DA REGRA 2: Artesanato PcD max R$ 50,00 e autor obrigatório
    CONSTRAINT check_artesanato_pcd_rules CHECK (
        category != 'artesanato' OR (price <= 50.00 AND author_pcd IS NOT NULL AND TRIM(author_pcd) != '')
    )
);

CREATE INDEX IF NOT EXISTS idx_products_status_category ON products(status, category);
CREATE INDEX IF NOT EXISTS idx_products_expires_at ON products(expires_at) WHERE status = 'reserved';

-- -----------------------------------------------------------------------------
-- 4. TABELA DE AGENDAMENTOS DE DOAÇÃO PRESENCIAL
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS donation_schedules (
    id VARCHAR(64) PRIMARY KEY,
    donor_user_id VARCHAR(64) REFERENCES users(id) ON DELETE CASCADE,
    donor_name VARCHAR(255) NOT NULL,
    donor_phone VARCHAR(30) NOT NULL,
    donor_email VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category donation_category_enum NOT NULL,
    scheduled_date DATE NOT NULL,
    scheduled_time_slot VARCHAR(50) NOT NULL,
    image_url TEXT,
    status donation_status_enum NOT NULL DEFAULT 'scheduled',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    received_at TIMESTAMP WITH TIME ZONE,
    received_by_admin_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL
);

-- -----------------------------------------------------------------------------
-- 5. TABELA DE TRANSAÇÕES NO GUICHÊ & ARRECADAÇÃO
-- Cada R$ 50 arrecadados financiam 1 hora de terapia clínica de reabilitação
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sales_transactions (
    id VARCHAR(64) PRIMARY KEY,
    product_id VARCHAR(64) REFERENCES products(id),
    product_title VARCHAR(255) NOT NULL,
    category product_category_enum NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL, -- 'PIX IHL', 'Cartão Débito', 'Dinheiro'
    buyer_user_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    buyer_name VARCHAR(255) NOT NULL,
    therapy_hours_generated NUMERIC(6, 2) NOT NULL,
    confirmed_by_admin_id VARCHAR(64) REFERENCES users(id) ON DELETE SET NULL,
    confirmed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- 6. TRIGGER: CÁLCULO AUTOMÁTICO DE 168 HORAS (7 DIAS) AO RESERVAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_calculate_reservation_expiry()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'reserved' AND (OLD.status IS DISTINCT FROM 'reserved' OR NEW.reserved_at IS NOT NULL) THEN
        IF NEW.reserved_at IS NULL THEN
            NEW.reserved_at := CURRENT_TIMESTAMP;
        END IF;
        -- 168 horas = 7 dias exatos conforme Regra 1
        NEW.expires_at := NEW.reserved_at + INTERVAL '168 hours';
    END IF;

    IF NEW.status = 'available' THEN
        NEW.reserved_by_user_id := NULL;
        NEW.reserved_by_name := NULL;
        NEW.reserved_at := NULL;
        NEW.expires_at := NULL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_products_reservation_expiry ON products;
CREATE TRIGGER trg_products_reservation_expiry
    BEFORE INSERT OR UPDATE OF status, reserved_at ON products
    FOR EACH ROW
    EXECUTE FUNCTION trg_calculate_reservation_expiry();

-- -----------------------------------------------------------------------------
-- 7. FUNÇÃO DE MANUTENÇÃO: LIBERAÇÃO DE RESERVAS EXPIRADAS (> 168h)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION release_expired_reservations()
RETURNS INTEGER AS $$
DECLARE
    freed_count INTEGER;
BEGIN
    UPDATE products
    SET 
        status = 'available',
        reserved_by_user_id = NULL,
        reserved_by_name = NULL,
        reserved_at = NULL,
        expires_at = NULL
    WHERE status = 'reserved' AND expires_at < CURRENT_TIMESTAMP;

    GET DIAGNOSTICS freed_count = ROW_COUNT;
    RETURN freed_count;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- 8. FUNÇÃO LGPD: EXCLUSÃO IMEDIATA DE CONTA E DEVOLUÇÃO DE ITENS À VITRINE
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION delete_user_account_lgpd(p_user_id VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    -- 1. Libera qualquer produto que o usuário tinha reservado
    UPDATE products
    SET 
        status = 'available',
        reserved_by_user_id = NULL,
        reserved_by_name = NULL,
        reserved_at = NULL,
        expires_at = NULL
    WHERE reserved_by_user_id = p_user_id AND status = 'reserved';

    -- 2. Remove agendamentos de doação futuros/pendentes
    DELETE FROM donation_schedules
    WHERE donor_user_id = p_user_id AND status = 'scheduled';

    -- 3. Remove cadastro do usuário
    DELETE FROM users WHERE id = p_user_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- -----------------------------------------------------------------------------
-- 9. CARGA INICIAL DE DADOS (SEED) - IHL MOGI DAS CRUZES
-- -----------------------------------------------------------------------------
INSERT INTO users (id, name, email, phone, role, terms_accepted, terms_accepted_at) VALUES
('usr_mariana', 'Mariana Souza', 'mariana.souza@email.com', '(11) 98765-4321', 'comum', true, CURRENT_TIMESTAMP - INTERVAL '10 days'),
('usr_admin_carlos', 'Carlos Ribeiro (Monitor IHL)', 'admin@ihl.org.br', '(11) 97654-3210', 'admin', true, CURRENT_TIMESTAMP - INTERVAL '60 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO products (id, title, description, category, price, image_url, author_pcd, status) VALUES
('prod_art_1', 'Tapete Tear Ecológico Retalhos', 'Tapete artesanal confeccionado com fios de malha reaproveitados do Alto Tietê.', 'artesanato', 42.00, 'https://images.unsplash.com/photo-1600121848594-d8644e57abab', 'João M. (Oficina de Tear Adaptado)', 'available'),
('prod_art_2', 'Luminária Rústica Vidro & Macramê', 'Garrafa de azeite esterilizada customizada com cordão de algodão cru.', 'artesanato', 48.00, 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38', 'Ana Clara S. (Arte Sustentável)', 'available'),
('prod_art_3', 'Kit 3 Sabonetes Artesanais & Base Madeira', 'Sabonetes vegetais com essência cultivada no IHL.', 'artesanato', 35.00, 'https://images.unsplash.com/photo-1607006314177-3e817d23d854', 'Lucas P. (Oficina Terapêutica)', 'available'),
('prod_art_4', 'Quadro Mosaico em Azulejo Reciclado', 'Composição artística floral utilizando sobras de azulejos descartados.', 'artesanato', 50.00, 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119', 'Beatriz L. (Artes Visuais PcD)', 'available'),
('prod_bre_1', 'Jaqueta Jeans Clássica Vintage', 'Peça garimpada em ótimo estado de conservação, tamanho G.', 'brecho', 45.00, 'https://images.unsplash.com/photo-1576995853123-5a10305d93c0', NULL, 'available'),
('prod_bre_2', 'Vestido Midi Floral Primavera Tam M', 'Vestido com estampa floral delicada em viscose fluida.', 'brecho', 38.00, 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1', NULL, 'available'),
('prod_bre_3', 'Tênis Esportivo Casual Tam 41', 'Calçado esportivo amortecido em excelente estado de sola e cabedal.', 'brecho', 65.00, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff', NULL, 'available'),
('prod_mat_1', 'Lote com 2 Paletes Tratados (Padrão PBR)', 'Paletes de madeira lixados e prontos para sofás ou jardins verticais.', 'materiais', 30.00, 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7', NULL, 'available'),
('prod_mat_2', 'Conjunto 6 Garrafas Âmbar p/ Decoração', 'Garrafas de vidro âmbar esterilizadas para upcycling e decoração.', 'materiais', 20.00, 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae', NULL, 'available')
ON CONFLICT (id) DO NOTHING;
