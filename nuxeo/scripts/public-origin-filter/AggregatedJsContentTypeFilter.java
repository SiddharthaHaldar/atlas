package atlas.nuxeo;

import java.io.IOException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;

public final class AggregatedJsContentTypeFilter implements Filter {
    @Override
    public void init(FilterConfig config) {
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
            FilterChain chain) throws IOException, ServletException {
        if (request instanceof HttpServletRequest) {
            HttpServletRequest httpRequest = (HttpServletRequest) request;
            if (("GET".equals(httpRequest.getMethod())
                    || "HEAD".equals(httpRequest.getMethod()))
                    && httpRequest.getParameter("scripts") != null
                    && response.getContentType() == null) {
                response.setContentType("application/javascript");
            }
        }
        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {
    }
}