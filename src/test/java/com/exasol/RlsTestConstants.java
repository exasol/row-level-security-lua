package com.exasol;

public final class RlsTestConstants {
    public static final String USERS_TABLE = "EXA_RLS_USERS";
    public static final String GROUP_MEMBERSHIP_TABLE = "EXA_GROUP_MEMBERS";
    public static final String ROW_ROLES_COLUMN = "EXA_ROW_ROLES";
    public static final String ROW_GROUP_COLUMN = "EXA_ROW_GROUP";
    public static final String ROW_TENANT_COLUMN = "EXA_ROW_TENANT";
    public static final String USER_NAME_COLUMN = "EXA_USER_NAME";
    public static final String ROLE_MASK_COLUMN = "EXA_ROLE_MASK";
    public static final String GROUP_COLUMN = "EXA_GROUP";
    public static final String ROLE_MASK_TYPE = "DECIMAL(20,0)";
    public static final String IDENTIFIER_TYPE = "VARCHAR(128)";
    public static final int PUBLIC_ROLE_BIT_INDEX = 63;
    public static final String DOCKER_DB = "exasol/docker-db:7.1.10";

    private RlsTestConstants() {
        // prevent instantiation
    }
}