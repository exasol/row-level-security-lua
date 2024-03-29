--[[
CREATE OR REPLACE SCRIPT ADD_USER_TO_GROUP(user_name, array user_groups) AS
--]]
-- [impl -> dsn~assigning-users-to-groups~0]
import(exa.meta.script_schema .. '.EXA_IDENTIFIER', 'identifier')

function create_temporary_member_table()
    query([[CREATE OR REPLACE TABLE ::s.EXA_NEW_GROUP_MEMBERS
(EXA_USER_NAME VARCHAR(128) NOT NULL,
 EXA_GROUP VARCHAR(128) NOT NULL,
 CONSTRAINT UNIQUE_GROUP_MEMBERSHIP PRIMARY KEY (EXA_USER_NAME, EXA_GROUP) ENABLE
)]],
        { s = exa.meta.script_schema })
end

function populate_temporary_member_table()
    for i = 1, #user_groups do
        query("INSERT INTO ::s.EXA_NEW_GROUP_MEMBERS (EXA_USER_NAME, EXA_GROUP) VALUES (:u, :g)",
            { s = exa.meta.script_schema, u = user_name, g = user_groups[i] })
    end
end

function create_member_table_if_not_exists()
    query([[CREATE TABLE IF NOT EXISTS ::s.EXA_GROUP_MEMBERS
(EXA_USER_NAME VARCHAR(128) NOT NULL,
 EXA_GROUP VARCHAR(128) NOT NULL,
 CONSTRAINT UNIQUE_GROUP_MEMBERSHIP PRIMARY KEY (EXA_USER_NAME, EXA_GROUP) ENABLE
)]],
        { s = exa.meta.script_schema })
end

function merge_new_members()
    query([[MERGE INTO ::s.EXA_GROUP_MEMBERS M
            USING EXA_NEW_GROUP_MEMBERS N
            ON M.EXA_USER_NAME = N.EXA_USER_NAME AND M.EXA_GROUP = N.EXA_GROUP
            WHEN NOT MATCHED THEN INSERT VALUES (N.EXA_USER_NAME, N.EXA_GROUP)]],
    { s = exa.meta.script_schema })
end

function drop_temporary_member_table()
    query("DROP TABLE ::s.EXA_NEW_GROUP_MEMBERS", { s = exa.meta.script_schema })
end

identifier.assert_user_name(user_name)
identifier.assert_groups(user_groups)

create_temporary_member_table()
populate_temporary_member_table()
create_member_table_if_not_exists()
merge_new_members()
drop_temporary_member_table()
--[[
/
--]]
