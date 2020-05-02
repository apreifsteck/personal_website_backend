# APReifsteck

# TODO:
- [DONE?] Implement JWT auth for users
- USERS can only do CRUD on their own RESOURCES
- make IMAGES a PROTECTED resource
- IMAGE upload limit on BLOG POSTS
- Make it so that you can't upload more than two of the same IMAGE (or find a way to version them)
- UPLOAD size limit

Nuke images table (and schema)
create table 
    title
    description
    filename (string) UNIQUE_INDEX
    userid FK
    image (actual image from arc)

[DONE] prepackage/transform image data so that the params are what they should be
prefix filename to be unique. maybe #userid_#filename
insert into table after checking for unique constraint