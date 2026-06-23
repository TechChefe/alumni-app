-- =====================================================
-- Alumni Database for Department of Digital Systems
-- University of Thessaly - Advanced Web Apps Assignment 2
-- =====================================================

DROP DATABASE IF EXISTS alumni_db;
CREATE DATABASE alumni_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE alumni_db;

-- -----------------------------------------------------
-- Table: alumni
-- -----------------------------------------------------
CREATE TABLE alumni (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(80)  NOT NULL,
    last_name       VARCHAR(80)  NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    enrollment_year INT          NOT NULL,
    graduation_year INT          NULL,
    country         VARCHAR(80)  NOT NULL,
    created_at      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_last_name (last_name),
    INDEX idx_country (country),
    INDEX idx_years (enrollment_year, graduation_year)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- Table: jobs
-- -----------------------------------------------------
CREATE TABLE jobs (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    alumni_id   INT          NOT NULL,
    title       VARCHAR(150) NOT NULL,
    company     VARCHAR(150) NOT NULL,
    city        VARCHAR(100) NOT NULL,
    country     VARCHAR(80)  NOT NULL,
    latitude    DECIMAL(10,7) NOT NULL,
    longitude   DECIMAL(10,7) NOT NULL,
    start_date  DATE         NOT NULL,
    end_date    DATE         NULL,
    is_current  TINYINT(1)   NOT NULL DEFAULT 0,
    FOREIGN KEY (alumni_id) REFERENCES alumni(id) ON DELETE CASCADE,
    INDEX idx_alumni (alumni_id),
    INDEX idx_current (is_current)
) ENGINE=InnoDB;

-- =====================================================
-- Greece Euro 2004 Champions — 15 players as alumni
-- password hash = "password123"
-- =====================================================
INSERT INTO alumni (first_name, last_name, email, password_hash, enrollment_year, graduation_year, country) VALUES
('Antonios',    'Nikopolidis',      'antonios.nikopolidis@example.com',     '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 1998, 2002, 'Greece'),
('Giourkas',    'Seitaridis',       'giourkas.seitaridis@example.com',      '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 2000, 2004, 'Portugal'),
('Stylianos',   'Venetidis',        'stylianos.venetidis@example.com',      '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 1999, 2003, 'Greece'),
('Nikos',       'Dabizas',          'nikos.dabizas@example.com',            '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 1997, 2001, 'United Kingdom'),
('Traianos',    'Dellas',           'traianos.dellas@example.com',          '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 1999, 2003, 'Italy'),
('Angelos',     'Basinas',          'angelos.basinas@example.com',          '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 1999, 2003, 'Greece'),
('Theodoros',   'Zagorakis',        'theodoros.zagorakis@example.com',      '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 1996, 2000, 'Bulgaria'),
('Stelios',     'Giannakopoulos',   'stelios.giannakopoulos@example.com',   '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 1998, 2002, 'United Kingdom'),
('Angelos',     'Charisteas',       'angelos.charisteas@example.com',       '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 2002, 2006, 'Germany'),
('Giorgos',     'Karagounis',       'giorgos.karagounis@example.com',       '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 1997, 2001, 'Italy'),
('Demis',       'Nikolaidis',       'demis.nikolaidis@example.com',         '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 1997, 2001, 'Spain'),
('Takis',       'Fyssas',           'takis.fyssas@example.com',             '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 1997, 2001, 'Portugal'),
('Zisis',       'Vryzas',           'zisis.vryzas@example.com',             '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 1998, 2002, 'Italy'),
('Pantelis',    'Kafes',            'pantelis.kafes@example.com',           '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 2001, 2005, 'Greece'),
('Kostas',      'Chalkias',         'kostas.chalkias@example.com',          '$2b$12$liGzTINxmzPSL1CfU4a6u.BZ2RtXiXEuQ13VojU0aS2i.X3Ks/7pe', 1998, 2002, 'Greece');

-- =====================================================
-- Jobs — varied roles, cities, companies
-- =====================================================
INSERT INTO jobs (alumni_id, title, company, city, country, latitude, longitude, start_date, end_date, is_current) VALUES

-- 1: Antonios Nikopolidis - Athens, Greece (Goalkeeper → Sports Tech)
(1, 'Head of Sports Analytics',     'Panathinaikos FC',     'Athens',       'Greece',         37.9838000, 23.7275000, '2020-03-01', NULL, 1),
(1, 'Performance Coach',            'Greek Football Fed.',  'Athens',       'Greece',         37.9838000, 23.7275000, '2014-08-01', '2020-02-28', 0),

-- 2: Giourkas Seitaridis - Lisbon, Portugal (Right Back → Security)
(2, 'Cybersecurity Engineer',       'Altice Portugal',      'Lisbon',       'Portugal',       38.7223000, -9.1393000, '2021-05-01', NULL, 1),
(2, 'IT Security Analyst',          'NOS Telecom',          'Lisbon',       'Portugal',       38.7223000, -9.1393000, '2017-09-01', '2021-04-30', 0),

-- 3: Stylianos Venetidis - Thessaloniki, Greece (Defender → Fintech)
(3, 'Senior Software Engineer',     'Viva Wallet',          'Thessaloniki', 'Greece',         40.6401000, 22.9444000, '2019-06-01', NULL, 1),
(3, 'Backend Developer',            'Upstream Systems',     'Athens',       'Greece',         37.9838000, 23.7275000, '2015-10-01', '2019-05-31', 0),

-- 4: Nikos Dabizas - Leicester, UK (Centre Back → Data)
(4, 'Data Engineering Manager',     'Next PLC',             'Leicester',    'United Kingdom', 52.6369000, -1.1398000, '2020-02-01', NULL, 1),
(4, 'Data Analyst',                 'Experian',             'Nottingham',   'United Kingdom', 52.9548000, -1.1581000, '2016-03-01', '2020-01-31', 0),

-- 5: Traianos Dellas - Rome, Italy (Centre Back → Cloud)
(5, 'Cloud Solutions Architect',    'Engineering Group',    'Rome',         'Italy',          41.9028000, 12.4964000, '2021-01-10', NULL, 1),
(5, 'DevOps Engineer',              'Accenture Italia',     'Milan',        'Italy',          45.4654000,  9.1859000, '2016-07-01', '2020-12-31', 0),

-- 6: Angelos Basinas - Athens, Greece (Midfielder → Product)
(6, 'Product Manager',              'Skroutz',              'Athens',       'Greece',         37.9838000, 23.7275000, '2020-09-01', NULL, 1),
(6, 'Business Analyst',             'PwC Greece',           'Athens',       'Greece',         37.9838000, 23.7275000, '2015-01-01', '2020-08-31', 0),

-- 7: Theodoros Zagorakis - Sofia, Bulgaria (Captain/Midfielder → Management)
(7, 'Chief Technology Officer',     'Telelink Business',    'Sofia',        'Bulgaria',       42.6977000, 23.3219000, '2019-11-01', NULL, 1),
(7, 'VP Engineering',               'Musala Soft',          'Sofia',        'Bulgaria',       42.6977000, 23.3219000, '2014-05-01', '2019-10-31', 0),

-- 8: Stelios Giannakopoulos - Manchester, UK (Winger → AI)
(8, 'Machine Learning Engineer',    'AstraZeneca',          'Manchester',   'United Kingdom', 53.4808000, -2.2426000, '2021-04-01', NULL, 1),
(8, 'Data Scientist',               'Manchester City FC',   'Manchester',   'United Kingdom', 53.4808000, -2.2426000, '2017-06-01', '2021-03-31', 0),

-- 9: Angelos Charisteas - Bremen, Germany (Striker → EV/Automotive)
(9, 'Software Engineer',            'Mercedes-Benz',        'Stuttgart',    'Germany',        48.7758000,  9.1829000, '2020-08-01', NULL, 1),
(9, 'Junior Developer',             'Werder Bremen FC',     'Bremen',       'Germany',        53.0793000,  8.8017000, '2015-02-01', '2020-07-31', 0),

-- 10: Giorgos Karagounis - Milan, Italy (Midfielder → Consulting)
(10, 'Senior Consultant',           'Deloitte Italia',      'Milan',        'Italy',          45.4654000,  9.1859000, '2019-07-01', NULL, 1),
(10, 'Business Consultant',         'KPMG Italia',          'Rome',         'Italy',          41.9028000, 12.4964000, '2014-09-01', '2019-06-30', 0),

-- 11: Demis Nikolaidis - Madrid, Spain (Striker → Gaming)
(11, 'Game Developer',              'Scopely',              'Madrid',       'Spain',          40.4168000, -3.7038000, '2021-03-01', NULL, 1),
(11, 'Software Developer',          'Gameloft Iberia',      'Madrid',       'Spain',          40.4168000, -3.7038000, '2016-11-01', '2021-02-28', 0),

-- 12: Takis Fyssas - Lisbon, Portugal (Left Back → Fintech)
(12, 'Fullstack Developer',         'Revolut Portugal',     'Lisbon',       'Portugal',       38.7223000, -9.1393000, '2020-06-01', NULL, 1),
(12, 'Frontend Developer',          'Farfetch',             'Porto',        'Portugal',       41.1579000, -8.6291000, '2015-08-01', '2020-05-31', 0),

-- 13: Zisis Vryzas - Turin, Italy (Striker → Automotive)
(13, 'Systems Engineer',            'Stellantis',           'Turin',        'Italy',          45.0703000,  7.6869000, '2020-04-01', NULL, 1),
(13, 'Embedded Engineer',           'Fiat Chrysler',        'Turin',        'Italy',          45.0703000,  7.6869000, '2015-06-01', '2020-03-31', 0),

-- 14: Pantelis Kafes - Athens, Greece (Midfielder → Startup)
(14, 'Co-founder & CTO',            'Blueground',           'Athens',       'Greece',         37.9838000, 23.7275000, '2021-09-01', NULL, 1),
(14, 'Lead Developer',              'Workable',             'Athens',       'Greece',         37.9838000, 23.7275000, '2016-03-01', '2021-08-31', 0),

-- 15: Kostas Chalkias - Athens, Greece (Goalkeeper → Cybersecurity)
(15, 'Information Security Manager','Eurobank',             'Athens',       'Greece',         37.9838000, 23.7275000, '2019-10-01', NULL, 1),
(15, 'Security Analyst',            'Alpha Bank',           'Athens',       'Greece',         37.9838000, 23.7275000, '2014-11-01', '2019-09-30', 0);

-- =====================================================
-- Quick sanity checks:
-- SELECT COUNT(*) FROM alumni;                          -- expect 15
-- SELECT COUNT(*) FROM jobs WHERE is_current = 1;      -- expect 15
-- =====================================================
