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
-- Table: jobs (each alumnus may have multiple, one is "current")
-- -----------------------------------------------------
CREATE TABLE jobs (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    alumni_id   INT          NOT NULL,
    title       VARCHAR(150) NOT NULL,
    company     VARCHAR(150) NOT NULL,
    city        VARCHAR(100) NOT NULL,
    country     VARCHAR(80)  NOT NULL,
    latitude    DECIMAL(10, 7) NOT NULL,
    longitude   DECIMAL(10, 7) NOT NULL,
    start_date  DATE         NOT NULL,
    end_date    DATE         NULL,
    is_current  TINYINT(1)   NOT NULL DEFAULT 0,
    created_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (alumni_id) REFERENCES alumni(id) ON DELETE CASCADE,
    INDEX idx_alumni (alumni_id),
    INDEX idx_current (is_current)
) ENGINE=InnoDB;

-- =====================================================
-- SEED DATA: 14 realistic alumni
-- All passwords below are bcrypt hashes of "password123"
-- (so you can log in with any email + password123 for testing)
-- =====================================================

-- The hash $2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi
-- corresponds to the plaintext "password123"
INSERT INTO alumni (first_name, last_name, email, password_hash, enrollment_year, graduation_year, country) VALUES
('Maria',      'Papadopoulou',  'maria.papadopoulou@example.com',  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2014, 2018, 'Greece'),
('Nikolaos',   'Georgiou',      'nikolaos.georgiou@example.com',   '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2013, 2017, 'Germany'),
('Eleni',      'Konstantinou',  'eleni.konstantinou@example.com',  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2015, 2019, 'Netherlands'),
('Dimitris',   'Antoniou',      'dimitris.antoniou@example.com',   '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2012, 2016, 'United Kingdom'),
('Sofia',      'Vasileiou',     'sofia.vasileiou@example.com',     '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2016, 2020, 'Greece'),
('Konstantinos','Iordanidis',   'konstantinos.iordanidis@example.com','$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2011, 2015, 'United States'),
('Anna',       'Markou',        'anna.markou@example.com',         '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2017, 2021, 'Greece'),
('Giorgos',    'Stefanidis',    'giorgos.stefanidis@example.com',  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2014, 2018, 'Switzerland'),
('Christina',  'Lambrou',       'christina.lambrou@example.com',   '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2013, 2017, 'France'),
('Petros',     'Tsoukalas',     'petros.tsoukalas@example.com',    '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2015, 2019, 'Cyprus'),
('Katerina',   'Dimitriou',     'katerina.dimitriou@example.com',  '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2018, 2022, 'Greece'),
('Vasilis',    'Karagiannis',   'vasilis.karagiannis@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2010, 2014, 'Sweden'),
('Ioanna',     'Pappa',         'ioanna.pappa@example.com',        '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2016, 2020, 'Belgium'),
('Andreas',    'Mitropoulos',   'andreas.mitropoulos@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2012, 2016, 'Germany'),
('Despoina',   'Athanasiou',    'despoina.athanasiou@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 2017, 2021, 'Ireland');

-- -----------------------------------------------------
-- Jobs: at least one CURRENT job per alumnus, some have past jobs too
-- Coordinates correspond to real city centers (approximate)
-- -----------------------------------------------------
INSERT INTO jobs (alumni_id, title, company, city, country, latitude, longitude, start_date, end_date, is_current) VALUES
-- 1: Maria Papadopoulou - Athens, Greece
(1, 'Senior Software Engineer',     'Beat',                 'Athens',     'Greece',         37.9838000, 23.7275000, '2021-03-01', NULL, 1),
(1, 'Junior Developer',             'Workable',             'Athens',     'Greece',         37.9838000, 23.7275000, '2018-09-01', '2021-02-28', 0),

-- 2: Nikolaos Georgiou - Berlin, Germany
(2, 'Backend Developer',            'Zalando',              'Berlin',     'Germany',        52.5200000, 13.4050000, '2020-06-01', NULL, 1),
(2, 'Software Engineer',            'N26',                  'Berlin',     'Germany',        52.5200000, 13.4050000, '2017-10-01', '2020-05-31', 0),

-- 3: Eleni Konstantinou - Amsterdam, Netherlands
(3, 'Full Stack Developer',         'Booking.com',          'Amsterdam',  'Netherlands',    52.3676000,  4.9041000, '2019-08-15', NULL, 1),

-- 4: Dimitris Antoniou - London, UK
(4, 'DevOps Engineer',              'Monzo Bank',           'London',     'United Kingdom', 51.5074000, -0.1278000, '2020-01-10', NULL, 1),
(4, 'Systems Administrator',        'Revolut',              'London',     'United Kingdom', 51.5074000, -0.1278000, '2016-09-01', '2019-12-31', 0),

-- 5: Sofia Vasileiou - Thessaloniki, Greece
(5, 'Mobile Developer',             'Pfizer Hellas',        'Thessaloniki','Greece',        40.6401000, 22.9444000, '2020-09-01', NULL, 1),

-- 6: Konstantinos Iordanidis - San Francisco, USA
(6, 'Senior Cloud Architect',       'Salesforce',           'San Francisco','United States',37.7749000,-122.4194000, '2019-04-01', NULL, 1),
(6, 'Software Engineer',            'Oracle',               'San Francisco','United States',37.7749000,-122.4194000, '2015-08-01', '2019-03-31', 0),

-- 7: Anna Markou - Athens, Greece
(7, 'Data Scientist',               'Deloitte',             'Athens',     'Greece',         37.9838000, 23.7275000, '2021-07-15', NULL, 1),

-- 8: Giorgos Stefanidis - Zurich, Switzerland
(8, 'Machine Learning Engineer',    'Google',               'Zurich',     'Switzerland',    47.3769000,  8.5417000, '2020-11-01', NULL, 1),
(8, 'Research Engineer',            'ETH Zurich',           'Zurich',     'Switzerland',    47.3769000,  8.5417000, '2018-09-01', '2020-10-31', 0),

-- 9: Christina Lambrou - Paris, France
(9, 'Product Manager',              'Doctolib',             'Paris',      'France',         48.8566000,  2.3522000, '2020-02-01', NULL, 1),

-- 10: Petros Tsoukalas - Limassol, Cyprus
(10, 'Cybersecurity Analyst',       'Wargaming',            'Limassol',   'Cyprus',         34.7071000, 33.0226000, '2019-09-01', NULL, 1),

-- 11: Katerina Dimitriou - Patras, Greece
(11, 'Frontend Developer',          'Upstream',             'Athens',     'Greece',         37.9838000, 23.7275000, '2022-06-01', NULL, 1),

-- 12: Vasilis Karagiannis - Stockholm, Sweden
(12, 'Engineering Manager',         'Spotify',              'Stockholm',  'Sweden',         59.3293000, 18.0686000, '2018-05-01', NULL, 1),
(12, 'Senior Software Engineer',    'Klarna',               'Stockholm',  'Sweden',         59.3293000, 18.0686000, '2014-10-01', '2018-04-30', 0),

-- 13: Ioanna Pappa - Brussels, Belgium
(13, 'API Developer',               'European Commission',  'Brussels',   'Belgium',        50.8503000,  4.3517000, '2020-10-01', NULL, 1),

-- 14: Andreas Mitropoulos - Munich, Germany
(14, 'Tech Lead',                   'BMW Group',            'Munich',     'Germany',        48.1351000, 11.5820000, '2019-03-01', NULL, 1),
(14, 'Software Architect',          'Siemens',              'Munich',     'Germany',        48.1351000, 11.5820000, '2016-09-01', '2019-02-28', 0),

-- 15: Despoina Athanasiou - Dublin, Ireland
(15, 'Site Reliability Engineer',   'Stripe',               'Dublin',     'Ireland',        53.3498000, -6.2603000, '2021-08-01', NULL, 1);

-- =====================================================
-- Quick sanity checks:
-- SELECT COUNT(*) FROM alumni;     -- expect 15
-- SELECT COUNT(*) FROM jobs WHERE is_current = 1;  -- expect 15
-- =====================================================
