package atlas.nuxeo;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.Collections;
import java.util.Enumeration;
import java.util.LinkedHashSet;
import java.util.Set;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;

public final class PublicOriginFilter implements Filter {
    private static final String HEADER = "nuxeo-virtual-host";
    private String publicOrigin;

    @Override
    public void init(FilterConfig config) throws ServletException {
        String configuredUrl = System.getenv("NUXEO_URL");
        if (configuredUrl == null || configuredUrl.trim().isEmpty()) {
            throw new ServletException("PublicOriginFilter requires NUXEO_URL");
        }
        try {
            URI url = new URI(configuredUrl);
            if ((!"https".equalsIgnoreCase(url.getScheme())
                    && !"http".equalsIgnoreCase(url.getScheme()))
                    || url.getHost() == null || url.getUserInfo() != null) {
                throw new ServletException("NUXEO_URL must be an HTTP(S) URL without credentials");
            }
            publicOrigin = new URI(url.getScheme(), null, url.getHost(),
                    url.getPort(), "/", null, null).toASCIIString();
        } catch (URISyntaxException exception) {
            throw new ServletException("Invalid NUXEO_URL", exception);
        }
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
            FilterChain chain) throws IOException, ServletException {
        if (!(request instanceof HttpServletRequest)) {
            chain.doFilter(request, response);
            return;
        }
        HttpServletRequestWrapper wrapped = new HttpServletRequestWrapper(
                (HttpServletRequest) request) {
            @Override
            public String getHeader(String name) {
                return HEADER.equalsIgnoreCase(name) ? publicOrigin : super.getHeader(name);
            }

            @Override
            public Enumeration<String> getHeaders(String name) {
                return HEADER.equalsIgnoreCase(name)
                        ? Collections.enumeration(Collections.singleton(publicOrigin))
                        : super.getHeaders(name);
            }

            @Override
            public Enumeration<String> getHeaderNames() {
                Set<String> names = new LinkedHashSet<String>();
                Enumeration<String> original = super.getHeaderNames();
                while (original != null && original.hasMoreElements()) {
                    String name = original.nextElement();
                    if (!HEADER.equalsIgnoreCase(name)) {
                        names.add(name);
                    }
                }
                names.add(HEADER);
                return Collections.enumeration(names);
            }
        };
        chain.doFilter(wrapped, response);
    }

    @Override
    public void destroy() {
    }
}