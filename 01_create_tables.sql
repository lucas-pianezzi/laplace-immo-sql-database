CREATE TABLE REGION (
    code_region VARCHAR(3) PRIMARY KEY,
    nom_region VARCHAR(100)
);

CREATE TABLE DEPARTEMENT (
    code_departement VARCHAR(3) PRIMARY KEY,
    nom_departement VARCHAR(100),
    code_region VARCHAR(3) NOT NULL,
    FOREIGN KEY (code_region) REFERENCES REGION(code_region)
);

CREATE TABLE COMMUNE (
    code_insee VARCHAR(5) PRIMARY KEY,
    nom_commune VARCHAR(100),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    population_municipale INT,
    population_comptee_apart INT,
    code_departement VARCHAR(3) NOT NULL,
    FOREIGN KEY (code_departement) REFERENCES DEPARTEMENT(code_departement)
);

CREATE TABLE TYPE_BIEN (
    code_type_local INT PRIMARY KEY,
    libelle_type_local VARCHAR(50) NOT NULL
);

CREATE TABLE BIEN (
    id_bien INT PRIMARY KEY, 
    surface_carrez_1er_lot DECIMAL(6,2),
    nombre_pieces INT,
    code_insee VARCHAR(5) NOT NULL,
    code_type_local INT NOT NULL,
    FOREIGN KEY (code_insee) REFERENCES COMMUNE(code_insee),
    FOREIGN KEY (code_type_local) REFERENCES TYPE_BIEN(code_type_local)
);

CREATE TABLE MUTATION (
    id_mutation INT PRIMARY KEY,
    date_mutation DATE,
    nature_mutation VARCHAR(50),
    valeur_fonciere DECIMAL(12,2),
    id_bien INT NOT NULL,
    FOREIGN KEY (id_bien) REFERENCES BIEN(id_bien)
);