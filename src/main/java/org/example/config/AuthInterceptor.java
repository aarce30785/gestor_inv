package org.example.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.web.servlet.HandlerInterceptor;

public class AuthInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(
            HttpServletRequest request,
            HttpServletResponse response,
            Object handler
    ) throws Exception {

        String uri = request.getRequestURI();

        // Rutas públicas
        if (uri.equals("/login") || uri.startsWith("/css")) {
            return true;
        }

        HttpSession session = request.getSession(false);

        if (session == null || session.getAttribute("usuario") == null) {
            response.sendRedirect("/login");
            return false;
        }

        if (uri.startsWith("/usuarios")) {
            String rol = (String) session.getAttribute("rol");
            if (!"ADMIN".equals(rol)) {
                response.sendRedirect("/productos");
                return false;
            }
        }

        return true;
    }
}
