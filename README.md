# Banking-System-SQL
# Overview
<li>BankingSystem is a simple banking system implemented in SQL Server. It includes database schema, triggers, stored procedures, and example transactions designed to simulate basic banking operations.</li>

# Features
<ol>
<li><b>Database Schema</b></li>
<ul>
<li>Mastertbl: Stores customer account details including account ID, customer name, balances, status, and transaction limits.</li>
<li>Transactiontbl: Records all transactions associated with customer accounts.</li>
</ul>
<li><b>Stored Procedures</b></li>
<ul>
<li>AccTransaction: Manages different types of transactions such as deposits (CD), withdrawals (CW), checks (CQ), and non-business transactions (NB).</li>
<li>UpdateAndFetchPassBookbyAccId: Updates and retrieves transaction history (passbook) for a specific account ID.</li>
</ul>

<li><b>Triggers</b></li>

<ul>
 <li>trg_CreatePassbookTable: Automatically creates a passbook table for each new account ID inserted into Mastertbl. Ensures that passbook tables are uniquely named per account ID.</li>
</ul>
</ol>

# Usage
<h3>Setup</h3>
<ol>
<li>Database Creation</li>
  <ul>
    <li>Execute the SQL script to create the Trg_BankingSystem database.</li>
    <li>This script includes the creation of Mastertbl and Transactiontbl.</li>
  </ul>
<li>Stored Procedures</li>
<ul>
  
 <li>AccTransaction: Use this procedure to perform transactions (CD, CW, CQ, NB) on existing accounts.</li>
 <li>UpdateAndFetchPassBookbyAccId: Updates the passbook table and retrieves transaction history for a specified account ID.</li>

</ul>

<li>Triggers</li>
<ul>
<li>trg_CreatePassbookTable: Automatically creates a passbook table when a new account is added to Mastertbl.</li>
</ul>
</ol>


# Example Transactions
<li>Inserting a new customer:</li>
<code>insert into Mastertbl(acc_id, cname) values (1, 'Abc');</code>

<li>Performing transactions:</li>
<code>exec AccTransaction 1, 'CD', 1000000;
exec AccTransaction 1, 'CW', 10000;
exec AccTransaction 1, 'CQ', 10000;
</code>

<li>Updating and fetching passbook:</li>
<code>exec UpdateAndFetchPassBookbyAccId 1;
</code>

