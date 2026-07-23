<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    /* ------------------------------------------------------------------
       pageHeader.jsp  –  Reusable page header bar
       Set these request attributes BEFORE including this file:

         request.setAttribute("pageTitle",    "Ticket Dashboard");
         request.setAttribute("pageSubtitle", "Moulana Air Travels — Overview");
         request.setAttribute("pageIcon",     "fa-solid fa-ticket");   // FontAwesome class

       All three are optional; sensible defaults are used if omitted.
    ------------------------------------------------------------------ */
    String phTitle    = request.getAttribute("pageTitle")    != null ? (String) request.getAttribute("pageTitle")    : "Dashboard";
    String phSubtitle = request.getAttribute("pageSubtitle") != null ? (String) request.getAttribute("pageSubtitle") : "";
    String phIcon     = request.getAttribute("pageIcon")     != null ? (String) request.getAttribute("pageIcon")     : "fa-solid fa-gauge-high";
%>

<style>
    /* ── PAGE HEADER – structural only (colors in theme.css) ── */
    .ph-bar {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
        padding: 10px 20px;
        flex-shrink: 0;
    }

    .ph-left {
        display: flex;
        align-items: center;
        gap: 14px;
        min-width: 0;
    }

    .ph-icon-wrap {
        width: 44px;
        height: 44px;
        border-radius: 10px;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        font-size: 20px;
    }

    .ph-text { min-width: 0; }

    .ph-title {
        font-size: 18px;
        font-weight: 800;
        letter-spacing: .2px;
        line-height: 1.2;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .ph-subtitle {
        font-size: 12px;
        margin-top: 2px;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .ph-right {
        flex-shrink: 0;
        text-align: right;
    }

    #ph-datetime {
        font-size: 12.5px;
        letter-spacing: .2px;
    }
</style>

<div class="ph-bar">
    <div class="ph-left">
        <div class="ph-icon-wrap ph-icon-bg">
            <i class="<%=phIcon%>"></i>
        </div>
        <div class="ph-text">
            <div class="ph-title ph-title-color"><%=phTitle%></div>
            <% if (!phSubtitle.isEmpty()) { %>
            <div class="ph-subtitle ph-subtitle-color"><%=phSubtitle%></div>
            <% } %>
        </div>
    </div>
    <div class="ph-right">
        <span id="ph-datetime" class="ph-subtitle-color"></span>
    </div>
</div>

<script>
(function () {
    var el = document.getElementById('ph-datetime');
    if (!el) return;

    var days   = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    function pad(n) { return n < 10 ? '0' + n : n; }

    function tick() {
        var d  = new Date();
        var dy = days[d.getDay()];
        var dt = d.getDate();
        var mo = months[d.getMonth()];
        var yr = d.getFullYear();
        var h  = d.getHours();
        var m  = pad(d.getMinutes());
        var ap = h >= 12 ? 'pm' : 'am';
        h = h % 12 || 12;
        el.textContent = dy + ', ' + dt + ' ' + mo + ', ' + yr + ', ' + h + ':' + m + ' ' + ap;
    }

    tick();
    setInterval(tick, 60000);
})();
</script>
