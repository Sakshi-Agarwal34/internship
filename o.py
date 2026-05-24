import sqlite3 
conn = sqlite3.connect("sqlite.db")
conn.execute('''create table student1(sid integer primary key ,sname varchar(90),sclass varchar(20))''')
conn.execute('''create table  emp(empid integer primary key,empname varchar(100),empwork varchar(80))''')
conn.execute('''create table  villager(vname varchar(100),vwork varchar(80))''')

ins='insert into student1(sid,sname,sclass) values (5,"sakshi","4"),(6,"aa","7")'
jns='insert into emp(empid,empname,empwork) values (0,"bb","5"),(1,"cc","8")'
pns='insert into villager(vname,vwork) values("radha","doctor")'
conn.execute(ins)
conn.execute(jns)
conn.execute(pns)
conn.commit()
data=conn.execute("select*from student1 order by sname limit 2")
for m in data:
    print(m)


data1=conn.execute("select*from emp order by empname limit 2")
for n in data1:
    print(n)
empid=int(input("enter id"))
conn.execute("delete from emp where empid= ?", (empid,))
conn.commit()
data1=conn.execute("select*from emp order by empname limit 2")
for n in data1:
    print(n) 
data2=conn.execute("select*from villager where vwork='doctor'")
for s in data2:
    print(s)
  
conn.execute("update villager set vname='krishna' where vwork='doctor'")
conn.commit()
data2=conn.execute("select*from villager where vwork='doctor'")
for s in data2:
    print(s)


conn.close() 