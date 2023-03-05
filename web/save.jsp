<%@page import="praytimes.Config"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%><%
	Config cfg = new Config(request);
	cfg.store(response);
%><html>
<head>
	<script type="text/javascript">
		window.location = "/";
	</script>
</head>
</html>