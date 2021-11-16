---
-- This module contains the list of supported adapter capabilities.
--
return {
    -- Main capabilities
    "SELECTLIST_PROJECTION", "SELECTLIST_EXPRESSIONS",
    -- Literal capabilities
    "LITERAL_BOOL", "LITERAL_DATE", "LITERAL_DOUBLE", "LITERAL_EXACTNUMERIC", "LITERAL_INTERVAL", "LITERAL_NULL",
    "LITERAL_STRING", "LITERAL_TIMESTAMP", "LITERAL_TIMESTAMP_UTC",
    -- Predicate capabilities
    "FN_PRED_AND", "FN_PRED_EQUAL", "FN_PRED_IN_CONSTLIST", "FN_PRED_LESS", "FN_PRED_NOT", "FN_PRED_NOTEQUAL",
    "FN_PRED_OR",
    -- Scalar function capabilities
    "FN_ABS", "FN_ACOS", "FN_ADD", "FN_ADD_DAYS", "FN_ADD_HOURS", "FN_ADD_MINUTES", "FN_ADD_MONTHS",
    "FN_ADD_SECONDS", "FN_ADD_WEEKS", "FN_ADD_YEARS", "FN_ASCII", "FN_ASIN", "FN_ATAN", "FN_ATAN2", "FN_BIT_AND",
    "FN_BIT_LROTATE", "FN_BIT_LSHIFT", "FN_BIT_CHECK", "FN_BIT_LENGTH", "FN_BIT_NOT", "FN_BIT_OR", "FN_BIT_RROTATE",
    "FN_BIT_RSHIFT", "FN_BIT_SET", "FN_BIT_TO_NUM", "FN_BIT_XOR", "FN_CASE", "FN_CAST", "FN_CEIL", "FN_CHR",
    "FN_COLOGNE_PHONETIC", "FN_COS", "FN_COSH", "FN_CONCAT", "FN_CONVERT_TZ", "FN_COT", "FN_CURRENT_DATE",
    "FN_CURRENT_SCHEMA", "FN_CURRENT_SESSION", "FN_CURRENT_STATEMENT", "FN_CURRENT_TIMESTAMP", "FN_CURRENT_USER",
    "FN_DATE_TRUNC", "FN_DAY", "FN_DAYS_BETWEEN", "FN_DBTIMEZONE", "FN_DEGREES", "FN_DIV", "FN_DUMP",
    "FN_EDIT_DISTANCE", "FN_EXP", "FN_EXTRACT", "FN_FLOAT_DIV", "FN_FLOOR", "FN_FROM_POSIX_TIME", "FN_GREATEST",
    "FN_HASH_MD5", "FN_HASH_SHA1", "FN_HASH_SHA256", "FN_HASH_SHA512", "FN_HASH_TIGER", "FN_HASHTYPE_MD5",
    "FN_HASHTYPE_SHA1", "FN_HASHTYPE_SHA256", "FN_HASHTYPE_SHA512", "FN_HASHTYPE_TIGER", "FN_HOUR",
    "FN_HOURS_BETWEEN", "FN_INITCAP", "FN_INSERT", "FN_INSTR", "FN_IS_BOOLEAN", "FN_IS_DATE", "FN_IS_DSINTERVAL",
    "FN_IS_NUMBER", "FN_IS_TIMESTAMP", "FN_IS_YMINTERVAL", "FN_JSON_VALUE", "FN_LEAST", "FN_LENGTH", "FN_LN",
    "FN_LPAD", "FN_LOCALTIMESTAMP", "FN_LOCATE", "FN_LOG", "FN_LOWER", "FN_LTRIM", "FN_MINUTE",
    "FN_MINUTES_BETWEEN", "FN_MIN_SCALE", "FN_MOD", "FN_MONTH", "FN_MONTHS_BETWEEN", "FN_MULT", "FN_NEG",
    "FN_NULLIFZERO", "FN_NUMTODSINTERVAL", "FN_NUMTOYMINTERVAL", "FN_OCTET_LENGTH", "FN_POSIX_TIME", "FN_POWER",
    "FN_RADIANS", "FN_RAND", "FN_REGEXP_INSTR", "FN_REGEXP_REPLACE", "FN_REGEXP_SUBSTR", "FN_REPEAT", "FN_REPLACE",
    "FN_REVERSE", "FN_RIGHT", "FN_ROUND", "FN_RPAD", "FN_RTRIM", "FN_SECOND", "FN_SECONDS_BETWEEN",
    "FN_SESSIONTIMEZONE", "FN_SESSION_PARAMETER", "FN_SIGN", "FN_SIN", "FN_SINH", "FN_SOUNDEX", "FN_SPACE",
    "FN_SQRT", "FN_ST_AREA", "FN_ST_BOUNDARY", "FN_ST_BUFFER", "FN_ST_CENTROID", "FN_ST_CONTAINS",
    "FN_ST_CONVEXHULL", "FN_ST_CROSSES", "FN_ST_DIFFERENCE", "FN_ST_DIMENSION", "FN_ST_DISJOINT", "FN_ST_DISTANCE",
    "FN_ST_ENDPOINT", "FN_ST_ENVELOPE", "FN_ST_EQUALS", "FN_ST_EXTERIORRING", "FN_ST_FORCE2D", "FN_ST_GEOMETRYN",
    "FN_ST_GEOMETRYTYPE", "FN_ST_INTERIORRINGN", "FN_ST_INTERSECTION", "FN_ST_INTERSECTS", "FN_ST_ISCLOSED",
    "FN_ST_ISEMPTY", "FN_ST_ISRING", "FN_ST_ISSIMPLE", "FN_ST_LENGTH", "FN_ST_NUMGEOMETRIES",
    "FN_ST_NUMINTERIORRINGS", "FN_ST_NUMPOINTS", "FN_ST_OVERLAPS", "FN_ST_POINTN", "FN_ST_SETSRID",
    "FN_ST_STARTPOINT", "FN_ST_SYMDIFFERENCE", "FN_ST_TOUCHES", "FN_ST_TRANSFORM", "FN_ST_UNION",
    "FN_ST_WITHIN", "FN_ST_X", "FN_ST_Y", "FN_SUBSTR", "FN_SUB", "FN_SYS_GUID", "FN_SYSDATE", "FN_SYSTIMESTAMP",
    "FN_TAN", "FN_TANH", "FN_TO_CHAR", "FN_TO_DATE", "FN_TO_DSINTERVAL", "FN_TO_NUMBER", "FN_TO_TIMESTAMP",
    "FN_TO_YMINTERVAL", "FN_TRANSLATE", "FN_TRIM", "FN_TRUNC", "FN_TYPEOF", "FN_UNICODE", "FN_UNICODECHR",
    "FN_UPPER", "FN_WEEK", "FN_YEAR", "FN_YEARS_BETWEEN", "FN_ZEROIFNULL"
}
