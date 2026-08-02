package com.fittrack.common.observability;

public final class RequestContext {

    private static final ThreadLocal<Details> CURRENT = new ThreadLocal<>();

    private RequestContext() {
    }

    public static void set(String requestId, String clientAddress) {
        CURRENT.set(new Details(requestId, clientAddress));
    }

    public static Details get() {
        return CURRENT.get();
    }

    public static void clear() {
        CURRENT.remove();
    }

    public record Details(String requestId, String clientAddress) {
    }
}
