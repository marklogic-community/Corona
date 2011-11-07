if(typeof corona == "undefined" || !corona) {
    corona = {};
}


$(document).ready(function() {
    $("form.createUsers").submit(function() {
        var adminName = $("input.an");
        var adminPass1 = $("input.ap1");
        var adminPass2 = $("input.ap2");

        var devName = $("input.dn");
        var devPass1 = $("input.dp1");
        var devPass2 = $("input.dp2");

        var hasError = false;
        if(adminName.val().length === 0) {
            adminName.addClass("error");
            hasError = true;
        }
        else {
            adminName.removeClass("error");
        }
        if(adminPass1.val() !== adminPass2.val() || adminPass1.val().length === 0) {
            adminPass1.addClass("error");
            adminPass2.addClass("error");
            hasError = true;
        }
        else {
            adminPass1.removeClass("error");
            adminPass2.removeClass("error");
        }

        if(devName.val().length === 0) {
            devName.addClass("error");
            hasError = true;
        }
        else {
            devName.removeClass("error");
        }
        if(devPass1.val() !== devPass2.val() || adminPass1.val().length === 0) {
            devPass1.addClass("error");
            devPass2.addClass("error");
            hasError = true;
        }
        else {
            devPass1.removeClass("error");
            devPass2.removeClass("error");
        }

        if(hasError) {
            return false;
        }
    });
});
