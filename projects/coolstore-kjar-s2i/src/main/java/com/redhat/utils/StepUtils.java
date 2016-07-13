package com.redhat.utils;

public class StepUtils {
	
	public static final String KIE_SERVER_URL_PROP = "KIE_SERVER_URL";
	public static final String KIE_SERVER_USER_PROP = "KIE_SERVER_USER";
	public static final String KIE_SERVER_PASSWORD_PROP = "KIE_SERVER_PASSWORD";
	
	public static final String KIE_SERVER_URL_DEFAULT = "http://localhost:8080";
	public static final String KIE_SERVER_USER_DEFAULT = "admin";
	public static final String KIE_SERVER_PASSWORD_DEFAULT = "password";	

	
	
	public static String getKieServerUrl() {
		return getPropertyValue(KIE_SERVER_URL_PROP, KIE_SERVER_URL_DEFAULT);
	}
	
	public static String getKieServerUser() {
		return getPropertyValue(KIE_SERVER_USER_PROP, KIE_SERVER_USER_DEFAULT);
	}
	
	public static String getKieServerPassword() {
		return getPropertyValue(KIE_SERVER_PASSWORD_PROP, KIE_SERVER_PASSWORD_DEFAULT);
	}
	
	private static String getPropertyValue(String name, String defaultValue) {
        
		if (isSystemPropertySet(name)) {
            return System.getProperty(name);
        } else if (isEnvVarSet(name)) {
            return System.getenv(name);
        }

        return defaultValue;
		
	}
	

    private static boolean isEnvVarSet(final String name) {
        String val = System.getenv(name);
        return val != null && !val.isEmpty();
    }

    private static boolean isSystemPropertySet(final String name) {
        String val = System.getProperty(name);
        return val != null && !val.isEmpty();
    }

	
}
