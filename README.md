# ITSC204FinalProject (TEAM MOV)

This is a repository for **ITSC 204 - Final Project** in Fall 2022.

Every learner is required to do the following:
- Fork the repo
- Checkout your designated group's branch
- Commit often
- Do Pull Requests to **original** repo (your designated branch) often
- Have fun

# Project Summary: 

- Create a TCP client (using nasm stack syscalls) that will connect to the servers given ip/port. 
- Request a set amount of bits from the server between 0x100 and 0x5FF. (it will give randomized characters back)
- Create a output file for sorting the data received from targeted server.
  - the sort will use the **gnome sorting** algorithm
- Append sorted information to file. 

# Tasks: (not in any particular order)

- Review TCP Client test server
- Create and test code using the alogthrim for gnome sorting in NASM intel x86 64-bit structure
  - https://www.geeksforgeeks.org/gnome-sort-a-stupid-one/
- Create TCP Client server
- Make function(s) to make files and append files
- Make function(s) to request data between 0x100 and 0x5FF from the server.
  - Figure out how to store this data into an array using mmap/brk
  - Figure out how to free heap allocation after finishing requirements

# Start doucumentation of all steps taken and the understanding of them
 
- We will need this for our presentation. Make sure to use correct commenting techniques when coding.
