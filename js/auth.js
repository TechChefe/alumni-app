/**
 * Tiny auth module: stores JWT in sessionStorage and exposes a couple of helpers.
 */
const Auth = (() => {
    const KEY = 'alumni_jwt';
    const USR = 'alumni_user';

    function getToken()   { return sessionStorage.getItem(KEY); }
    function getUser()    {
        const raw = sessionStorage.getItem(USR);
        return raw ? JSON.parse(raw) : null;
    }
    function setSession(token, user) {
        sessionStorage.setItem(KEY, token);
        sessionStorage.setItem(USR, JSON.stringify(user));
    }
    function clear() {
        sessionStorage.removeItem(KEY);
        sessionStorage.removeItem(USR);
    }
    function isLoggedIn() { return !!getToken(); }

    function authHeader() {
        const t = getToken();
        return t ? { Authorization: 'Bearer ' + t } : {};
    }

    return { getToken, getUser, setSession, clear, isLoggedIn, authHeader };
})();
