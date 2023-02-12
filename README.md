### Open Redirect Scanner

- You must have the following programs installed and in your PATH:
    - ffuf
    - amass
    - gf
    - amass
  
### Usage
``` 
./find_redirects --target somesite.com --listener http://pingb.in/p/abcde1234 --subdomains <yes/no>
```

- If your listener gets hit, check the file redirects_found.txt to see which request triggered the redirect.
