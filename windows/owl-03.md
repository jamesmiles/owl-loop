## System Under Test
Windows Calculator

## Preconditions
- Calculator should be in Standard mode with the display cleared

## Test Intent
Divide 42 by 0

## Expected Result
The calculator display shows "Cannot divide by zero"

## Test Steps

Step 1 — Open Calculator
- Launch Calculator via Start Menu or `calc.exe`

Step 2 — Clear the display
- Press 'Escape' to ensure the display is reset to 0

Step 3 — Enter '4' then '2'
- Press '4', then '2' so the display reads "42"

Step 4 — Press divide
- Press '/' to enter the divide operator

Step 5 — Enter '0'
- Press '0' so the display reads "0"

Step 6 — Press equals
- Press '=' to compute the result

Step 7 — Verify result
- Confirm the calculator display shows "Cannot divide by zero"
