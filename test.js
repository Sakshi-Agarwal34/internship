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
