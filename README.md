The Codes Implement Modified Nodal Analysis-a technique that is used by SPICE softwares to solve circuits.To run the program, downnload all the .m Matlab scripts and put them in the same folder.
Open the GUI file and it should take you to the matlab App Designer segment and hit the 'RUN' button from the top bar--a interface of the program should open.
The FORMAT HELP button has the netlist writing manual to guide an user, refer to that if faced with any complexity. 
Note to any future reader:
This code can be extended to cover many functions of actual SPICE softwares. The solution vector X already contains all the information needed for a circuit.You can look up segments like 
adding  DC sweep and AC sweep. For transient analysis try to make a different .m script, as that's gonna contain and extract circuit informations at small time intervals -so basically you have to call 
the solve_mna function over and over. Feel free to explore the possibilities ,that is all!
