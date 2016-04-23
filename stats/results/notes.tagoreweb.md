## Table structure of tagoreweb.in data is as follows:

+----------------------+--------------+---------------------------------------------------------+
| Column               | Type         | Modifiers                                               |
|----------------------+--------------+---------------------------------------------------------|
| id                   | integer      |  not null default nextval('tagoreweb_id_seq'::regclass) |
| letter               | character(1) |                                                         |
| number               | text         |                                                         |
| link                 | text         |                                                         |
| name                 | text         |                                                         |
| lyrics               | text         |                                                         |
| parjaay              | text         |                                                         |
| raag                 | text         |                                                         |
| taal                 | text         |                                                         |
| written_on_bengali   | text         |                                                         |
| written_on_gregorian | text         |                                                         |
| music                | text         |                                                         |
| place                | text         |                                                         |
| misc_data            | jsonb        |                                                         |
+----------------------+--------------+---------------------------------------------------------+
Indexes:
    "tagoreweb_pkey" PRIMARY KEY, btree (id)
    "tagoreweb_link_key" UNIQUE CONSTRAINT, btree (link)
    "tagoreweb_name_parjaay_index" UNIQUE, btree (name, parjaay)
    "tagoreweb_letter_index" btree (letter)
    "tagoreweb_name_index" btree (name)
    "tagoreweb_parjaay_index" btree (parjaay)
