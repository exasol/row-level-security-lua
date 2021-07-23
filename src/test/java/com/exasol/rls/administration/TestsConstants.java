package com.exasol.rls.administration;

import java.math.BigInteger;
import java.nio.file.Path;
import java.util.List;

public final class TestsConstants {
    // Lua scripts
    private static final Path ADMIN_SCRIPT_BASE_PATH = Path.of("src/com.exasol.rls.administration/");
    public static final Path PATH_TO_EXA_RLS_BASE = ADMIN_SCRIPT_BASE_PATH.resolve("exa_rls_base.lua");
    public static final Path PATH_TO_EXA_IDENTIFIER = ADMIN_SCRIPT_BASE_PATH.resolve("exa_identifier.lua");
    public static final Path PATH_TO_ADD_RLS_ROLE = ADMIN_SCRIPT_BASE_PATH.resolve("add_rls_role.lua");
    public static final Path PATH_TO_DELETE_RLS_ROLE = ADMIN_SCRIPT_BASE_PATH.resolve("delete_rls_role.lua");
    public static final Path PATH_TO_ASSIGN_ROLES_TO_USER = ADMIN_SCRIPT_BASE_PATH.resolve("assign_roles_to_user.lua");
    public static final Path PATH_TO_ADD_USER_TO_GROUP = ADMIN_SCRIPT_BASE_PATH.resolve("add_user_to_group.lua");
    public static final Path PATH_TO_REMOVE_USER_FROM_GROUP = ADMIN_SCRIPT_BASE_PATH
            .resolve("remove_user_from_group.lua");
    public static final Path PATH_TO_LIST_ALL_GROUPS = ADMIN_SCRIPT_BASE_PATH.resolve("list_all_groups.lua");
    public static final Path PATH_TO_LIST_ALL_ROLES = ADMIN_SCRIPT_BASE_PATH.resolve("list_all_roles.lua");
    public static final Path PATH_TO_LIST_USER_GROUPS = ADMIN_SCRIPT_BASE_PATH.resolve("list_user_groups.lua");
    public static final Path PATH_TO_LIST_USER_ROLES = ADMIN_SCRIPT_BASE_PATH.resolve("list_user_roles.lua");
    public static final Path PATH_TO_LIST_USERS_AND_ROLES = ADMIN_SCRIPT_BASE_PATH.resolve("list_users_and_roles.lua");
    public static final Path PATH_TO_BIT_POSITIONS = ADMIN_SCRIPT_BASE_PATH.resolve("bit_positions.lua");

    // SQL scripts
    private static final Path SQL_SCRIPT_BASE_PATH = Path.of("src/main/sql/");
    public static final Path PATH_TO_ROLE_MASK = SQL_SCRIPT_BASE_PATH.resolve("role_mask.sql");
    public static final long MAX_ROLE_VALUE = BigInteger.valueOf(2).pow(63).subtract(BigInteger.valueOf(1)).longValue();
    // [impl->dsn~public-access-role-id~1]]
    public static final long DEFAULT_ROLE_MASK = BigInteger.valueOf(2).pow(63).longValue();
    public static final String EXA_ROW_ROLES_COLUMN_NAME = "EXA_ROW_ROLES";
    public static final String EXA_ROW_TENANT_COLUMN_NAME = "EXA_ROW_TENANT";
    public static final String EXA_ROW_GROUP_COLUMN_NAME = "EXA_ROW_GROUP";
    public static final String EXA_RLS_USERS_TABLE_NAME = "EXA_RLS_USERS";
    public static final String EXA_ROLES_MAPPING_TABLE_NAME = "EXA_ROLES_MAPPING";
    public static final String EXA_GROUP_MEMBERS_TABLE_NAME = "EXA_GROUP_MEMBERS";
    public static final List<String> RLS_COLUMNS = List.of(EXA_ROW_ROLES_COLUMN_NAME, EXA_ROW_TENANT_COLUMN_NAME,
            EXA_ROW_GROUP_COLUMN_NAME);
    public static final List<String> RLS_METADATA_TABLES = List.of(EXA_RLS_USERS_TABLE_NAME,
            EXA_ROLES_MAPPING_TABLE_NAME, EXA_GROUP_MEMBERS_TABLE_NAME);
    public static final String DOCKER_DB = "exasol/docker-db:7.0.10";
    private TestsConstants() {
        // prevent instantiation
    }
}
