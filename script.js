document.getElementById("registerForm").addEventListener("submit", function(event){

    event.preventDefault();

    let name = document.getElementById("name").value.trim();
    let email = document.getElementById("email").value.trim();
    let password = document.getElementById("password").value;
    let branch = document.getElementById("branch").value;
    let mobile = document.getElementById("mobile").value.trim();

    let message = document.getElementById("message");

    let emailPattern = /^[^ ]+@[^ ]+\.[a-z]{2,3}$/;
    let mobilePattern = /^[6-9]\d{9}$/;

    if(name==""){
        message.style.color="red";
        message.innerHTML="Please enter your name.";
        return;
    }

    if(!email.match(emailPattern)){
        message.style.color="red";
        message.innerHTML="Please enter a valid email.";
        return;
    }

    if(password.length<6){
        message.style.color="red";
        message.innerHTML="Password must be at least 6 characters.";
        return;
    }

    if(branch==""){
        message.style.color="red";
        message.innerHTML="Please select a branch.";
        return;
    }

    if(!mobile.match(mobilePattern)){
        message.style.color="red";
        message.innerHTML="Enter a valid 10-digit mobile number.";
        return;
    }

    message.style.color="green";
    message.innerHTML="Registration Successful!";

    document.getElementById("registerForm").reset();

});