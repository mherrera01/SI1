-- Creamos una nueva tabla languages
CREATE TABLE languages (
	language character varying(32) NOT NULL,
    languageid integer NOT NULL,

    CONSTRAINT languages_pkey PRIMARY KEY (languageid)
);

-- Creamos una secuencia para los id de language
CREATE SEQUENCE languages_languageid_seq
increment 1 START 1 NO minvalue NO maxvalue cache 1;

-- Añadimos la secuencia a la primary key de la tabla languages
ALTER TABLE only languages
ALTER COLUMN languageid SET default nextval('languages_languageid_seq'::regclass);

-- Añadimos los nombres de los idiomas a la tabla
INSERT INTO languages
SELECT DISTINCT language
FROM imdb_movielanguages;

-- Actualizamos la tabla imdb_movielanguages. Ahora tendrá una foreign key
-- a la nueva tabla languages
UPDATE imdb_movielanguages
SET language = languages.languageid
FROM languages WHERE imdb_movielanguages.language = languages.language;

ALTER TABLE imdb_movielanguages
    ALTER COLUMN language TYPE integer USING(language::integer),
    ADD CONSTRAINT imdb_movielanguages_movieid_fkey2 foreign key (language)
        REFERENCES languages(languageid)
;

-- Creamos una nueva tabla genres
CREATE TABLE genres (
	genre character varying(32) NOT NULL,
    genreid integer NOT NULL,
    icon character varying(128),

    CONSTRAINT genres_pkey PRIMARY KEY (genreid)
);

-- Creamos una secuencia para los id de genre
CREATE SEQUENCE genres_genreid_seq
increment 1 START 1 NO minvalue NO maxvalue cache 1;

-- Añadimos la secuencia a la primary key de la tabla genres
ALTER TABLE only genres
ALTER COLUMN genreid SET default nextval('genres_genreid_seq'::regclass);

-- Añadimos los nombres de los géneros a la tabla
INSERT INTO genres
SELECT DISTINCT genre
FROM imdb_moviegenres;

-- Actualizamos la tabla imdb_movielgenres. Ahora tendrá una foreign key
-- a la nueva tabla genres
UPDATE imdb_moviegenres
SET genre = genres.genreid
FROM genres WHERE imdb_moviegenres.genre = genres.genre;

ALTER TABLE imdb_moviegenres
    ALTER COLUMN genre TYPE integer USING(genre::integer),
    ADD CONSTRAINT imdb_moviegenres_genreid_fkey2 foreign key (genre)
        REFERENCES genres(genreid)
;

-- Añadir foreign keys que faltan a las tablas orderdetail, imdb_actormovies, inventory y orders
ALTER TABLE orderdetail
    ADD CONSTRAINT orderdetail_orderid_fkey foreign key (orderid)
        REFERENCES orders(orderid),
    ADD CONSTRAINT orderdetail_prod_id_fkey2 foreign key (prod_id)
        REFERENCES products(prod_id)
;

ALTER TABLE imdb_actormovies
    ADD CONSTRAINT imdb_actormovies_actorid_fkey foreign key (actorid)
        REFERENCES imdb_actors(actorid),
    ADD CONSTRAINT imdb_actormovies_movieid_fkey2 foreign key (movieid)
        REFERENCES imdb_movies(movieid)
;

ALTER TABLE inventory
    ADD CONSTRAINT inventory_prod_id_fkey foreign key (prod_id)
        REFERENCES products(prod_id)
;

ALTER TABLE orders
    ADD CONSTRAINT orders_orderid_fkey foreign key (customerid)
        REFERENCES customers(customerid)
;

-- Quitamos del título de las película el año, ya que tenemos un campo separado para éste
UPDATE imdb_movies
SET movietitle=substring(movietitle FROM 0 for LENGTH(movietitle) - 6);

-- Creamos una nueva tabla countries
CREATE TABLE countries (
    country character varying(32) NOT NULL,
    countryid integer NOT NULL,

    CONSTRAINT countries_pkey PRIMARY KEY (countryid)
);

-- Creamos una secuencia para los id de countries
CREATE SEQUENCE countries_countryid_seq
increment 1 START 1 NO minvalue NO maxvalue cache 1;

-- Añadimos la secuencia a la primary key de la tabla countries
ALTER TABLE only countries
ALTER COLUMN countryid SET default nextval('countries_countryid_seq'::regclass);

-- Añadimos los nombres de los países a la tabla
INSERT INTO countries
SELECT DISTINCT country
FROM imdb_moviecountries;

-- Añadir a movies una foreign key al id del país y dos campos de texto
-- (poster y preview) correspondientes a las rutas de las fotos
ALTER TABLE imdb_movies
    ADD countryid integer,
    ADD poster character varying(128),
    ADD preview character varying(128),
    ADD sinopsis character varying(512),
    ADD puntuacion numeric,
    ADD CONSTRAINT imdb_movies_countryid_fkey FOREIGN KEY (countryid)
        REFERENCES countries(countryid)
;

-- Añadir a customers una foreign key al id del país
ALTER TABLE customers
    ADD countryid integer,

    ADD CONSTRAINT customers_countryid_fkey FOREIGN KEY (countryid)
        REFERENCES countries(countryid)
;

-- Cambiar la id del país para que sea el país que ponía en imdb_moviecountries
UPDATE imdb_movies
SET countryid = c.countryid
FROM countries c, imdb_moviecountries mc
WHERE
    imdb_movies.movieid = mc.movieid AND
    mc.country = c.country
;

-- Cambiar la id del país para que sea el país que ponía en customer.country
UPDATE customers
SET countryid = c.countryid
FROM countries c
WHERE
    customers.country = c.country
;

-- Borramos la columna country, que sería redundante ahora que tenemos country id
ALTER TABLE customers
    DROP COLUMN country
;

-- Borramos la tabla moviecountry que ya no necesitamos
DROP TABLE imdb_moviecountries;

-- Creamos una nueva tabla alertas que requiere el trigger updInventory para indicar
-- si no hay stock de una película que se quiere comprar
CREATE TABLE alertas (
    prod_id integer NOT NULL,
    alertadate date NOT NULL,
    stock integer NOT NULL,

    CONSTRAINT alertas_prod_id_fkey foreign key (prod_id)
    REFERENCES products(prod_id)
);

-- Insertamos nuestras películas a la tabla imdb_movies
INSERT INTO imdb_movies
VALUES ('800000', 'Interestellar', '', '0', '2014', '0', '35',
        'static/media/movies/Interestellar.jpg', 'static/media/previews/Interestellar.jpg',
        'Cuando la vida humana en la Tierra se ve amenazada por una plaga que mata los
         cultivos, Cooper, ex-piloto de la Nasa, se embarcará en una aventura por el espacio en
         busca de un planeta habitable al que puedan trasladar a la humanidad.', '8.5'),
       ('800001', 'Your Name', '', '0', '2016', '0', '52',
        'static/media/movies/YourName.jpg', 'static/media/previews/YourName.jpg',
        'El joven Taki vive en Tokio: la joven Mitsuha, en un pequeño pueblo en las montañas.
         Durante el sueño, los cuerpos de ambos se intercambian. Recluidos en un cuerpo que les
         resulta extraño, comienzan a comunicarse.', '6.8')
;

-- Insertamos el precio de nuestras películas a la tabla products
INSERT INTO products
VALUES ('6657', '800000', '12.99', 'Standard'),
       ('6658', '800001', '8.99', 'Standard')
;

-- Insertamos los géneros de nuestras películas a la tabla imdb_moviegenres
INSERT INTO imdb_moviegenres
VALUES ('800000', '9'),
       ('800000', '22'),
       ('800001', '6'),
       ('800001', '14')
;

-- Insertamos a la tabla inventory el stock de nuestras películas
INSERT INTO inventory
VALUES ('6657', '100', '0'),
       ('6658', '100', '0')
;

-- Actualizamos la tabla genres con los iconos de las categorías
UPDATE genres
SET icon = (CASE WHEN genre = 'History'      THEN 'static/media/icons/Historico.png'
                 WHEN genre = 'Action'       THEN 'static/media/icons/Action.png'
                 WHEN genre = 'Animation'    THEN 'static/media/icons/Animation.png'
                 WHEN genre = 'Adventure'    THEN 'static/media/icons/Aventuras.png'
                 WHEN genre = 'Comedy'       THEN 'static/media/icons/Comedy.png'
                 WHEN genre = 'Romance'      THEN 'static/media/icons/Romance.png'
                 WHEN genre = 'War'          THEN 'static/media/icons/Belico.png'
                 WHEN genre = 'Drama'        THEN 'static/media/icons/Drama.png'
                 WHEN genre = 'Family'       THEN 'static/media/icons/Infantil.png'
                 WHEN genre = 'Sci-Fi'       THEN 'static/media/icons/SciFi.png'
                 WHEN genre = 'Film-Noir'    THEN 'static/media/icons/Suspense.png'
                 WHEN genre = 'Thriller'     THEN 'static/media/icons/Psicologica.png'
                 WHEN genre = 'Horror'       THEN 'static/media/icons/Terror.png'
            END)
WHERE genre IN ('History', 'Action', 'Animation', 'Adventure', 'Comedy', 'Romance',
                'War', 'Drama', 'Family', 'Sci-Fi', 'Film-Noir', 'Thriller', 'Horror')
;
