## Table structure for geetabitan.com data is as follows:

+---------------------+---------+----------------------------------------------------------+
| Column              | Type    | Modifiers                                                |
|---------------------+---------+----------------------------------------------------------|
| id                  | integer |  not null default nextval('geetabitan_id_seq'::regclass) |
| letter              | text    |                                                          |
| link                | text    |                                                          |
| english_name        | text    |                                                          |
| bengali_name        | text    |  not null                                                |
| lyrics              | text    |                                                          |
| parjaay             | text    |                                                          |
| taal                | text    |                                                          |
| raag                | text    |                                                          |
| written_on          | text    |                                                          |
| notes               | text    |                                                          |
| place               | text    |                                                          |
| collection          | text    |                                                          |
| book                | text    |                                                          |
| notation            | text    |                                                          |
| staff_notation_pdf  | text    |                                                          |
| staff_notation_midi | text    |                                                          |
| english_lyrics      | text    |                                                          |
| english_translation | text    |                                                          |
| misc_data           | json    |                                                          |
+---------------------+---------+----------------------------------------------------------+
Indexes:
    "geetabitan_pkey" PRIMARY KEY, btree (id)
    "geetabitan_english_name_key" UNIQUE CONSTRAINT, btree (english_name)
    "geetabitan_link_key" UNIQUE CONSTRAINT, btree (link)

