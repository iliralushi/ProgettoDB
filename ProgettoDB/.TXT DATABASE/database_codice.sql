/* Creazione delle tabelle */

CREATE TABLE Persona (
    CF VARCHAR(16) PRIMARY KEY,
    Nome VARCHAR(50) NOT NULL,
    Cognome VARCHAR(50) NOT NULL,
    Genere CHAR(1) NOT NULL,
    NomeArtista VARCHAR(50) UNIQUE
);

CREATE TABLE Utente (
    Username VARCHAR(50) PRIMARY KEY,
    Nome VARCHAR(50) NOT NULL,
    Cognome VARCHAR(50) NOT NULL,
    Stato VARCHAR(50) NOT NULL,
    Città VARCHAR(50) NOT NULL
);

CREATE TABLE Abbonamento (
    ID SERIAL PRIMARY KEY,
    NomeAbbonamento VARCHAR(100) NOT NULL,
    Costo NUMERIC(10, 2),
    FOREIGN KEY (NomeAbbonamento) REFERENCES Utente(Username)
);

CREATE TABLE PuntoVendita (
    Codice INTEGER PRIMARY KEY,
    Nome VARCHAR(50) NOT NULL
);

CREATE TABLE Giuria (
    Codice INTEGER PRIMARY KEY,
    N_Giudici INTEGER NOT NULL
);

CREATE TABLE Album (
    Nome VARCHAR(100) PRIMARY KEY,
    Genere VARCHAR(50) NOT NULL,
    NomeDArte VARCHAR(50) NOT NULL,
    FOREIGN KEY (NomeDArte) REFERENCES Persona(NomeArtista)
);

CREATE TABLE Brano (
    ID INTEGER PRIMARY KEY,
    Nome VARCHAR(100) UNIQUE,
    NomeAlbum VARCHAR(100),
    Genere VARCHAR(50) NOT NULL,
    Durata TIME NOT NULL,
    FOREIGN KEY (NomeAlbum) REFERENCES Album(Nome)
);

CREATE TABLE Biglietto (
    Codice INTEGER PRIMARY KEY,
    Costo NUMERIC(10, 2) NOT NULL,
    CodicePV INTEGER NOT NULL,
    FOREIGN KEY (CodicePV) REFERENCES PuntoVendita(Codice)
);

CREATE TABLE Spettatore (
    CF VARCHAR(16) PRIMARY KEY,
    Nome VARCHAR(100),
    Cognome VARCHAR(100),
    Età INTEGER
);

CREATE TABLE Vincitore (
    IDFestival INTEGER PRIMARY KEY,
    IDBrano INTEGER,
    PunteggioMedio NUMERIC
);

CREATE TABLE Festival (
    ID INTEGER PRIMARY KEY,
    Conduttore VARCHAR(100) NOT NULL,
    Località VARCHAR(100) NOT NULL
);


CREATE TABLE FestivalPassato (
    ID INTEGER PRIMARY KEY,
    Anno INTEGER NOT NULL,
    Conduttore VARCHAR(100) NOT NULL,
    FestivalID INTEGER NOT NULL,
    FOREIGN KEY (FestivalID) REFERENCES Festival(ID)
);

CREATE TABLE Valuta (
    Username VARCHAR(50) NOT NULL,
    Nome VARCHAR(50) NOT NULL,
    Voto INTEGER NOT NULL,
    PRIMARY KEY (Username, Nome),
    FOREIGN KEY (Username) REFERENCES Utente(Username),
    FOREIGN KEY (Nome) REFERENCES Brano(Nome)
);

CREATE TABLE Sottoscrive (
    Username VARCHAR(50) NOT NULL,
    IDAbbonamento INTEGER NOT NULL,
    PRIMARY KEY (Username, IDAbbonamento),
    FOREIGN KEY (Username) REFERENCES Utente(Username),
    FOREIGN KEY (IDAbbonamento) REFERENCES Abbonamento(ID)
);

CREATE TABLE Punteggio (
    VotoBrano INTEGER NOT NULL,
    NomeBrano VARCHAR(100) NOT NULL,
    FOREIGN KEY (NomeBrano) REFERENCES Brano(Nome)
);


CREATE TABLE Lista (
    Username VARCHAR(50) NOT NULL,
    ID INTEGER PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    FOREIGN KEY (Username) REFERENCES Utente(Username)
);

CREATE TABLE Ricerca (
    IDFestival INTEGER NOT NULL,
    NomeDArte VARCHAR(50) NOT NULL,
    IDUtente VARCHAR(50) NOT NULL,
    FOREIGN KEY (IDFestival) REFERENCES Festival(ID),
    FOREIGN KEY (NomeDArte) REFERENCES Persona(NomeArtista),
    FOREIGN KEY (IDUtente) REFERENCES Utente(Username),
    PRIMARY KEY (IDFestival, NomeDArte, IDUtente)
);

CREATE TABLE Pagina (
    NPaginaArtista INTEGER PRIMARY KEY,
    IDFestival INTEGER NOT NULL,
    NomeDArte VARCHAR(50) NOT NULL,
    IDBrano VARCHAR(100) NOT NULL,
    FOREIGN KEY (IDFestival) REFERENCES Festival(ID),
    FOREIGN KEY (NomeDArte) REFERENCES Persona(NomeArtista),
    FOREIGN KEY (IDBrano) REFERENCES Brano(Nome)
);


CREATE TABLE RecensioneGiuria (
    CodiceGiuria INTEGER,
    IDBrano INTEGER,
    Motivazione VARCHAR(300),
    FOREIGN KEY (IDBrano) REFERENCES Brano(ID),
    FOREIGN KEY (CodiceGiuria) REFERENCES Giuria(Codice)
);


CREATE TABLE RecensioneSpettatore (
    CodiceSpettatore VARCHAR(16),
    IDBrano INTEGER,
    Motivazione VARCHAR(30),
    FOREIGN KEY (IDBrano) REFERENCES Brano(ID)
);

_______________________________________________________________________________________________________________

/* Viste */

/* Vista per visualizzare le informazioni sugli artisti partecipanti */

CREATE VIEW InformazioniArtisti AS
SELECT * FROM Persona;

/* Vista per visualizzare le informazioni sull’edizione corrente e su quelle passate */

CREATE VIEW InformazioniEdizioni AS
SELECT * FROM Festival;

/* Vista per visualizzare la media dei punteggi assegnati a ciascun brano */

CREATE VIEW MediaPunteggi AS
SELECT Nome, AVG(Voto) AS MediaPunteggio
FROM Valuta
GROUP BY Nome;

_______________________________________________________________________________________________________________

/* Indici */

/* Indice per ottimizzare le query che ordinano Album */
CREATE INDEX idx_album_nomedarte ON Album (NomeDArte);

/* Indice per ottimizzare le query ordinano Artisti */
CREATE INDEX idx_persona_nomeartista ON Persona (NomeArtista);

/* Indice per ottimizzare le query ordinano Branii */
CREATE INDEX idx_brano_nome ON Brano (Nome);


_______________________________________________________________________________________________________________


/* Trigger */

1. Il punteggio deve essere esclusivamente da 0 a 10.

CREATE OR REPLACE FUNCTION check_punteggio_range()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Voto < 0 OR NEW.Voto > 10 THEN
        RAISE EXCEPTION 'Il punteggio deve essere compreso tra 0 e 10.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_punteggio_range
BEFORE INSERT OR UPDATE ON Valuta
FOR EACH ROW
EXECUTE FUNCTION check_punteggio_range();

2. Una lista riguarda solo i brani o gli artisti.

CREATE OR REPLACE FUNCTION check_lista_type()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Brano WHERE Brano.Nome = NEW.Nome) AND 
       EXISTS (SELECT 1 FROM Persona WHERE Persona.NomeArtista = NEW.Nome) THEN
        RAISE EXCEPTION 'La lista deve riguardare solo brani o solo artisti.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_lista_type
BEFORE INSERT OR UPDATE ON Lista
FOR EACH ROW
EXECUTE FUNCTION check_lista_type();

3. L’utente abbonato può creare infinite liste base:

CREATE OR REPLACE FUNCTION check_abbonato_crea_lista()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Sottoscrive WHERE Sottoscrive.Username = NEW.Username) THEN
        RAISE EXCEPTION 'Solo gli utenti abbonati possono creare liste.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_abbonato_crea_lista
BEFORE INSERT ON Lista
FOR EACH ROW
EXECUTE FUNCTION check_abbonato_crea_lista();

4. Solo l’utente abbonato può accedere ai festival passati.

CREATE OR REPLACE FUNCTION check_abbonato_access_festival_passati()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Sottoscrive WHERE Sottoscrive.Username = NEW.Username) THEN
        RAISE EXCEPTION 'Solo gli utenti abbonati possono accedere ai festival passati.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_abbonato_access_festival_passati
BEFORE INSERT ON FestivalPassato
FOR EACH ROW
EXECUTE FUNCTION check_abbonato_access_festival_passati();

5. Le pagine possono contenere solo informazioni su artisti oppure sul festival.

CREATE OR REPLACE FUNCTION check_pagina_content()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.NomeDArte IS NOT NULL AND NEW.IDFestival IS NOT NULL) OR 
       (NEW.NomeDArte IS NULL AND NEW.IDFestival IS NULL) THEN
        RAISE EXCEPTION 'Le pagine possono contenere informazioni o sugli artisti o sul festival, non entrambi.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_pagina_content
BEFORE INSERT OR UPDATE ON Pagina
FOR EACH ROW
EXECUTE FUNCTION check_pagina_content();

6. Verifica se lo spettatore ha 7 anni o meno.

CREATE OR REPLACE FUNCTION check_spettatore_eta()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Spettatore WHERE Spettatore.CF = NEW.CodiceSpettatore AND Spettatore.Età <= 7) THEN
        RAISE EXCEPTION 'Lo spettatore con 7 anni o meno può entrare senza biglietto.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_spettatore_eta
BEFORE INSERT ON Biglietto
FOR EACH ROW
EXECUTE FUNCTION check_spettatore_eta();

7. La recensione degli spettatori può essere di al massimo 50 parole.

CREATE OR REPLACE FUNCTION check_recensione_spettatore()
RETURNS TRIGGER AS $$
BEGIN
    IF array_length(string_to_array(NEW.motivazione, ' '), 1) > 50 THEN
        RAISE EXCEPTION 'La recensione degli spettatori non può superare le 50 parole.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_recensione_spettatore
BEFORE INSERT OR UPDATE ON RecensioneSpettatore
FOR EACH ROW
EXECUTE FUNCTION check_recensione_spettatore();


8. La recensione di giuria può essere al massimo di 300 parole.

CREATE OR REPLACE FUNCTION check_recensione_giuria()
RETURNS TRIGGER AS $$
BEGIN
    IF array_length(string_to_array(NEW.motivazione, ' '), 1) > 300 THEN
        RAISE EXCEPTION 'La recensione della giuria non può superare le 300 parole.';
    END IF;
    RETURN NEW;
END;CREATE TABLE Vincitore (
    IDFestival INT PRIMARY KEY,
    IDBrano INT,
    PunteggioMedio NUMERIC
);
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_recensione_giuria
BEFORE INSERT OR UPDATE ON RecensioneGiuria
FOR EACH ROW
EXECUTE FUNCTION check_recensione_giuria();


9. Sceglie un vincitore per il festival.

CREATE OR REPLACE FUNCTION calcola_vincitore()
RETURNS TRIGGER AS $$
DECLARE
    media_spettatori NUMERIC;
    media_giuria NUMERIC;
    media_utenti NUMERIC;
    punteggio_totale NUMERIC;
BEGIN
    SELECT AVG(voto) INTO media_spettatori
    FROM Valuta
    WHERE Nome IN (SELECT Nome FROM Brano WHERE ID = NEW.IDBrano);

    SELECT AVG(CAST(motivazione AS NUMERIC)) INTO media_giuria
    FROM RecensioneGiuria
    WHERE idbrano = NEW.IDBrano;

    SELECT AVG(voto) INTO media_utenti
    FROM Valuta
    WHERE Username IN (SELECT Username FROM Utente WHERE Username = NEW.Username);

    punteggio_totale := (media_spettatori + (2 * media_giuria) + media_utenti) / 4;

    INSERT INTO Vincitore (IDFestival, IDBrano, PunteggioMedio)
    VALUES (NEW.IDFestival, NEW.IDBrano, punteggio_totale)
    ON CONFLICT (IDFestival) DO UPDATE
    SET IDBrano = NEW.IDBrano, PunteggioMedio = punteggio_totale;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

10. Vincitore scelto dopo che la giuria ha pubblicato una recensione.

CREATE TRIGGER trg_calcola_vincitore
AFTER INSERT OR UPDATE ON RecensioneGiuria
FOR EACH ROW
WHEN (SELECT COUNT(*) FROM RecensioneGiuria WHERE idbrano = NEW.idbrano) = (SELECT N_Giudici FROM Giuria WHERE Codice = NEW.codicegiuria)
EXECUTE FUNCTION calcola_vincitore();


__________________________________________________________________________________________________________________


/* Query PERSONA */
 
1. Può comprare biglietti.

INSERT INTO Biglietto (Codice, costo, CodicePV)
VALUES ('B001', 50.00, 101);


2. Può vendere biglietti ad altre persone.

UPDATE Biglietto
SET CodicePV = 102


3. Può lasciare una recensione corta di 50 parole.

INSERT INTO RecensioneSpettatore (codiceSpettatore, idbrano, motivazione)
VALUES ('9d2b0cb6-a6b9-45', 1, 'aaaaaro!');
select * from recensionespettatore where codicespettatore = '9d2b0cb6-a6b9-45'


4. Può valutare il brano di ogni artista.

INSERT INTO Valuta (Username, Nome, Voto)
VALUES ('user1', 'Rock Anthem', 5);

5. La giuria può fare una recensione di massimo 300 parole.

INSERT INTO RecensioneGiuria (codicegiuria, idbrano, motivazione)
VALUES (201, 1, 'Questo brano è un capolavoro, con una composizione eccellente e una performance straordinaria. La qualità del suono è impeccabile, e il testo è profondamente emozionante. Sicuramente uno dei migliori brani dell’anno.'); 


6. Possono scegliere il vincitore.


ALTER TABLE Festival ADD Vincitore VARCHAR(100);
UPDATE Festival
SET Vincitore = 'Rockstar'
WHERE ID = 1;

__________________________________________________________________________________________________________________

/* Query UTENTE */ 

1. Cerca informazioni sugli artisti partecipanti:

SELECT Nome, Cognome, Genere, NomeArtista
FROM Persona;

2. Cerca informazioni sulla edizione corrente e su quelle passate:

SELECT *
FROM Festival;

3. Valuta il brano di ogni artista:

SELECT NomeBrano, AVG(Voto) AS MediaVoti
FROM Valuta
GROUP BY NomeBrano;

4. Seleziona artisti di genere maschile o femminile:

SELECT NomeArtista
FROM Persona
WHERE Genere = 'Rock';


5. Inserisce un abbonamento:

INSERT INTO Abbonamento (ID, Utente)
VALUES (1, 'NomeUtente');


6. Visualizza la media dei punteggi assegnati al brano:

SELECT Nome, AVG(Voto) AS MediaVoti
FROM Valuta
GROUP BY Nome


7. Accedere alla anteprima degli album rilasciati da artisti.

SELECT Nome, Genere
FROM Album;


8. Aggiungi o modifica di un entry.

/* Aggiunta di una entry */
INSERT INTO RecensioneGiuria (CodiceGiuria, IDBrano, Motivazione)
VALUES (1, 1, 'Recensione fantastica!');

/* Modifica di una entry */
UPDATE Festival
SET Conduttore = 'NuovoConduttore'
WHERE ID = 1;

/* Query Complesse */

1. Trova gli utenti che sono o di New York o che di una città con prima lettera L:

SELECT * FROM Utente WHERE città = 'New York' OR città LIKE 'L%'

2. Trova gli album che sono del genere Hip-Hop o Pop:

SELECT DISTINCT  P.NomeArtista AS Artista
FROM Persona AS P
JOIN Album AS A ON P.NomeArtista = A.NomeDArte
JOIN Brano AS B ON A.Nome = B.NomeAlbum
WHERE B.Genere = 'Pop' OR B.Genere = 'Hip Hop'

3. Trova i brani che hanno una media di voti superiore a 4, insieme alle informazioni sugli album e gli artisti:

SELECT B.Nome AS Nome, B.NomeAlbum, A.Genere, P.Nome, P.Cognome, MediaPunteggio
FROM (
    SELECT Nome, AVG(Voto) AS MediaPunteggio
    FROM Valuta
    GROUP BY Nome
    HAVING AVG(Voto) > 3
) AS VotiAlti
JOIN Brano AS B ON VotiAlti.Nome = B.Nome
JOIN Album AS A ON B.NomeAlbum = A.Nome
JOIN Persona AS P ON A.NomeDArte = P.NomeArtista;

4. Recupera gli artisti che non hanno mai pubblicato un brano di genere "Pop":

SELECT *
FROM Persona
WHERE NOT EXISTS (
    SELECT *
    FROM Brano
    JOIN Album ON Brano.NomeAlbum = Album.Nome
    WHERE Album.NomeDArte = Persona.NomeArtista
    AND Brano.Genere = 'Pop'
);

5. Trova gli artisti che hanno un brano con un voto medio superiore alla media di tutti i brani:

SELECT P.NomeArtista, P.Nome, P.Cognome
FROM Persona AS P
WHERE EXISTS (
    SELECT 1
    FROM Brano AS B
    JOIN Valuta AS V ON B.Nome = V.Nome
    WHERE B.NomeDArte = P.NomeArtista
    GROUP BY B.Nome
    HAVING AVG(V.Voto) > (
        SELECT AVG(Voto)
        FROM Valuta
    )
);

6. Recupera gli artisti che hanno pubblicato almeno un brano in tutti gli album che hanno una durata totale superiore a 1 ora:

SELECT *
FROM Persona
WHERE NOT EXISTS (
    SELECT *
    FROM Album
    WHERE Album.NomeDArte = Persona.NomeArtista
    AND NOT EXISTS (
        SELECT *
        FROM Brano
        WHERE Brano.NomeAlbum = Album.Nome
    )
    AND (
        SELECT SUM(EXTRACT(EPOCH FROM Durata)) / 3600
        FROM Brano
        WHERE Brano.NomeAlbum = Album.Nome
    ) <= 1
);
