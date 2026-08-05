function checkFile(fileName) {
    fetch(fileName)
        .then(response => {
            if (response.ok) {
                console.log(fileName + " : File Exists");
            } else {
                console.log(fileName + " : File Not Found");
            }
        })
        .catch(error => {
            console.log(fileName + " : File Not Found");
        });
}

// Test Cases
checkFile("index.html");
checkFile(style.css);
checkFile(script.js);
// Validation Function
function validateStudent(name, email, mobile, branch) {

    if (name.trim() === "") {
        return "FAIL: Name cannot be empty";
    }

    let emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailPattern.test(email)) {
        return "FAIL: Invalid Email";
    }

    let mobilePattern = /^[0-9]{10}$/;
    if (!mobilePattern.test(mobile)) {
        return "FAIL: Mobile number must be 10 digits";
    }

    if (branch === "") {
        return "FAIL: Branch is required";
    }

    return "PASS: Registration Successful";
}


// ---------- Test Cases ----------

// TC1: Valid Data
console.log("TC1:", validateStudent(
    "Sakshi",
    "sakshi@gmail.com",
    "9876543210",
    "CSE"
));

// TC2: Empty Name
console.log("TC2:", validateStudent(
    "",
    "sakshi@gmail.com",
    "9876543210",
    "CSE"
));

// TC3: Invalid Email
console.log("TC3:", validateStudent(
    "Sakshi",
    "sakshigmail.com",
    "9876543210",
    "CSE"
));

// TC4: Mobile Less Than 10 Digits
console.log("TC4:", validateStudent(
    "Sakshi",
    "sakshi@gmail.com",
    "987654321",
    "CSE"
));

// TC5: Mobile Contains Letters
console.log("TC5:", validateStudent(
    "Sakshi",
    "sakshi@gmail.com",
    "98AB543210",
    "CSE"
));

// TC6: Branch Not Selected
console.log("TC6:", validateStudent(
    "Sakshi",
    "sakshi@gmail.com",
    "9876543210",
    ""
));