package com.exasol;

import java.sql.ResultSet;
import java.time.Duration;

public final class TimedResultSet {
    private final ResultSet resultSet;
    private final Duration duration;

    public TimedResultSet(final ResultSet resultSet, final Duration duration) {
        this.resultSet = resultSet;
        this.duration = duration;
    }

    public ResultSet getResultSet() {
        return this.resultSet;
    }

    public Duration getDuration() {
        return this.duration;
    }
}