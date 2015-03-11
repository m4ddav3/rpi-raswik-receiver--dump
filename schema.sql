CREATE TABLE device_types (id integer not null primary key, tag text not null, name text not null);
CREATE TABLE devices (id integer not null primary key, type integer not null references device_types, location integer not null references locations, tag text not null unique, name text not null unique, ident text not null);
CREATE TABLE locations (id integer not null primary key, name text);
CREATE TABLE samples (id integer not null primary key, time integer not null, message text, device integer references devices);
CREATE TABLE sensor_params (id integer not null primary key, sensor integer not null references sensors, key text not null, value text not null);
CREATE TABLE sensor_types (id integer not null primary key, name text);
CREATE TABLE sensors (id integer not null primary key, device integer not null references devices, type integer not null references sensor_types);

