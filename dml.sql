--all of these used canned values for the queries/transaction that may be substituted for variable bindings in the perl
--gets count of users with right password/userid, used for logging in
select count(*) from users where userid=rossman and password=fire;
--adds user to user db so they can now login
insert into users values('rossman', 'fire', 'rossman@aol.com');
--gets names of portfolios with given owner
select name from portfolios where owner='rossman';
--deletes portfolios where owner is rossman and name of portfolio is bleh
delete from portfolios where owner='rossman' and name='bleh';
--makes a portfolio with an initial cash value of 1000, name of bleh and owned by rossman
insert into portfolios (name, cash, owner) values('bleh', '1000', 'rossman');
--
--this inserts into a portfolios(whose id is 1) stock holdings of AAPL and 20 shares;
insert into holdings values('AAPL', '1', '20');	
--
--this gets the last close price of a stock given the symbol(AAPL for this one)
select symbol, close, timestamp from (select symbol, close, timestamp from cs339.stocksdaily union all select symbol, close, timestamp from stocksdailyaddon) where timestamp=(select MAX(last) from (select last from cs339.stockssymbols where symbol=rpad('AAPL',16) union all select last from stockssymbolsaddon where symbol=rpad('AAPL',16))) and symbol=rpad('AAPL', 16);
--
--gets all stocks/count of shares where portfolio id is 1
select symbol, count from holdings where portfolioid='1';
--
--gets portfolio id given name of owner and name of portfolio
select id from portfolios where owner='rossman' and name='bleh';
--
--gets amount of cash in portfolio account given portfolio id
select cash from portfolios where id='1';
--
--adds 20 to current value of cash in portfolio where id = 1
update portfolios set cash=cash+20 where id='1';
--
--subtracts 20 from current val of cash in port where id = 1
update portfolios set cash=(cash-20) where id='1';
--
--*******pretty sure timestamp WILL NOT WORK as it is just canned
--adds user/actual stock data to our table of stocksymboladdon where the symbol is 
--AAPL and the stock # is 40 and the first timestamp is 101099 and the last is 101010
insert into stockssymbolsaddon values('AAPL','40','101099','101010');
--
--adds user/real input into daily stock info for AAPL with the given values added to the table
insert into stocksdailyaddon values('AAPL', '101010', '20', '55', '1', '33', '100129');