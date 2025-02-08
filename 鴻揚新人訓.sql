-- 新人訓SQL部分共25題，記錄答案之後搭配issue

-- Q1
-- 取得台北市的顧客id
select CustomerID
from Customers
where City = '台北市'

-- Q2
-- 取得特定產品的庫存總數
select sum(UnitsInStock) as UnitsInStock
from Products
where ProductName in ('胡椒粉', '海鮮粉', '辣椒粉')

-- Q3
-- 取得部分員工姓名並且以姓名排序
select EmployeeName
from Employees
where TitleOfCourtesy = '小姐' and Title = '業務'
order by EmployeeName

-- Q4
-- 取得在2004年有購買過的顧客id，並且去重複
-- 以下寫法等價
select distinct EmployeeID
from Orders
where year(OrderDate) = '2004'
-- select distinct EmployeeID
-- from Orders
-- where datepart(year, OrderDate) = '2004'

-- Q5
-- 取得2003年前10筆訂單的員工id
select top 10 EmployeeID
from Orders
where year(OrderDate) = '2003'
order by OrderDate

-- Q6
-- 取得地址在屏東，且至少供應三項產品的供應商id
-- 使用SupplierID進行join，此情境用left, right, inner, full join結果都一樣，但是設計上用inner才合理
select Suppliers.SupplierID
from Suppliers inner join Products
  on Suppliers.SupplierID = Products.SupplierID
where Address like '屏東%'
group by Suppliers.SupplierID
having count(Products.ProductName) >= 3

-- Q7
-- 計算林姓員工的數量
select count(*) as Num
from Employees
where EmployeeName like '林%'

-- Q8
-- 取得供應商名稱，並排除有提供肉品或海鮮的供應商
-- 先取得有提供肉品或海鮮的供應商id，再將這些id排除，取得剩餘供應商的名稱
select distinct Suppliers.CompanyName
from Products, Categories, Suppliers
where Products.CategoryID = Categories.CategoryID and Products.SupplierID = Suppliers.SupplierID
  and Products.SupplierID not in (
    select distinct Products.SupplierID
    from Categories, Products
    where Categories.CategoryID = Products.CategoryID
	  and Categories.CategoryName in ('肉/家禽', '海鮮')
  )
order by Suppliers.CompanyName

-- Q9
-- 列出各分類的名稱及產品數量
select Categories.CategoryName, count(Products.ProductName) as Num
from Categories inner join Products
  on Categories.CategoryID = Products.CategoryID
group by Categories.CategoryID, Categories.CategoryName
order by Categories.CategoryID

-- Q10
-- 取得2004年各類產品都買過的會員id
-- 經過多次的join，得到CustomerID和CategoryID的對應表
-- 原做法: 去重複後計算會員出現的次數是否等同Categories的類別數量
-- 新做法: 取得所有會員id對所有分類的對應，再從中過濾得到86個「有至少一分類沒購買過」的會員，再用其過濾總會員92人，結果得到的6人就是「每個分類都買過的會員」

select CustomerID from Customers
-- 使用not in對所有會員過濾至少一分類沒買的會員，得到的就是每個分類都買過的會員
where CustomerID not in (
  -- 至少一種分類沒購買的會員才能在此收集到會員id
  select CustomerID
  from (
    -- 取得分類*會員數，總共8*92種可能的組合
    select CategoryID, CustomerID
	-- 轉為CatIDs和CusIDs是為了減少暫存table大小
    from (select CategoryID from Categories) as CatIDs,
      (select CustomerID from Customers) as CusIDs
  ) as totalCustomerCats
  -- 將所有可能過濾掉實際存在的購買組合
  where not exists (
    -- 取得2004年所有訂單的分類和客戶id對應表
    select Categories.CategoryID, Orders2.CustomerID
    from Categories, Products, OrderDetails, (
      select OrderID, CustomerID
      from Orders
      where year(OrderDate) = 2004
    ) as Orders2
    where Categories.CategoryID = Products.CategoryID and Products.ProductID = OrderDetails.ProductID and Orders2.OrderID = OrderDetails.OrderID
      and totalCustomerCats.CategoryID = Categories.CategoryID and totalCustomerCats.CustomerID = Orders2.CustomerID
    group by Categories.CategoryID, Orders2.CustomerID
  )
)

-- Q11
-- 計算各年的訂單總金額和平均金額
-- 這題題目要求欄位名「Years」，但是答案用的是「Year」
select year(OrderDate) as Years,
  count(Orders.OrderID) as Counts,
  round(sum(Price), 2) as PriceSum,
  round(avg(Price), 2) as PriceAverage
from Orders
  join (
    -- 由於一張訂單(OrderID)可能有多項產品(ProductID)，需要先去重複
  select OrderID, sum(UnitPrice * Quantity * (1 - Discount)) as Price
  from OrderDetails
  group by OrderID
  ) as OrderDetails2
    on Orders.OrderID = OrderDetails2.OrderID
group by year(OrderDate)
order by PriceSum desc

-- Q12
-- 取得2002年20筆訂單以上的員工id
select EmployeeID
from Orders
where year(OrderDate) = 2002
group by EmployeeID
having count(EmployeeID) >= 20

-- Q13
-- 列出每年用最多次的貨運方式id
-- 建立重複使用的暫存table
select year(OrderDate) as Years, ShipVia, count(OrderID) as OrderCount
into #benjamin_temp13_1
from Orders
group by year(OrderDate), ShipVia

select #benjamin_temp13_1.Years, ShipVia
from #benjamin_temp13_1
  join (
  select Years, max(OrderCount) as MaxOrderCount
  from #benjamin_temp13_1
  group by Years
  ) as temp2
    on #benjamin_temp13_1.OrderCount = temp2.MaxOrderCount
order by Years
-- 刪除暫存table
drop table #benjamin_temp13_1

-- Q13-2
-- 和上面的做法差不多，不過用with可能比較容易辨認出建立暫存資料表的目的，
with benjamin_temp13_1 (Years, ShipVia, OrderCount)
as (
  select year(OrderDate) as Years, ShipVia, count(OrderID) as OrderCount
  from Orders
  group by year(OrderDate), ShipVia
)

select benjamin_temp13_1.Years, ShipVia
from benjamin_temp13_1
  join (
  select Years, max(OrderCount) as MaxOrderCount
  from benjamin_temp13_1
  group by Years
  ) as temp2
    on benjamin_temp13_1.OrderCount = temp2.MaxOrderCount
order by Years

-- Q14
-- 列出以下兩家公司都處理過的員工id和姓名
select Employees.EmployeeID, Employees.EmployeeName
from Employees join (
  select temp1.EmployeeID
  from (
    select distinct EmployeeID
    from Customers join Orders
      on Customers.CustomerID = Orders.CustomerID
    where CompanyName = '凱誠國際顧問公司'
  ) as temp1
    join (
    select distinct EmployeeID
    from Customers join Orders
      on Customers.CustomerID = Orders.CustomerID
    where CompanyName = '師大貿易'
    ) as temp2
      on temp1.EmployeeID = temp2.EmployeeID
) as temp3
  on Employees.EmployeeID = temp3.EmployeeID

-- Q14-2
-- 使用intersect可以少一次join (mySql不能用)
select Employees.EmployeeID, Employees.EmployeeName
from Employees join (
  select distinct EmployeeID
  from Customers join Orders on Customers.CustomerID = Orders.CustomerID
  where CompanyName = '凱誠國際顧問公司'
  intersect
  select distinct EmployeeID
  from Customers join Orders on Customers.CustomerID = Orders.CustomerID
  where CompanyName = '師大貿易'
) as temp1
  on Employees.EmployeeID = temp1.EmployeeID

-- Q15
-- 列出六月生日員工的姓名
select EmployeeName
from Employees
where MONTH(BirthDate) = 6
order by EmployeeName

-- Q16
-- 取出延誤的訂單並顯示延誤天數
select OrderID, datediff(day, RequiredDate, ShippedDate) as DelayDays
from Orders
where datediff(day, RequiredDate, ShippedDate) > 0
order by OrderID

-- Q17
-- 取得主管的id, 姓名, 薪水，及其屬下的平均薪水
select Managers.EmployeeID, Managers.EmployeeName, Managers.Salary, count(Managers.EmployeeID) as SubCount, avg(Employees.Salary) as SubAvgSalary
from Employees as Managers
  join Employees
    on Managers.EmployeeID = Employees.ManagerID
group by Managers.EmployeeID, Managers.EmployeeName, Managers.Salary

-- Q18
-- 根據庫存的情況印出不同狀態的文字
select ProductID, ProductName, UnitsInStock, UnitsOnOrder, ReorderLevel,
case
  when UnitsInStock >= ReorderLevel then 'safe'
  when UnitsInStock + UnitsOnOrder >= ReorderLevel then 'reordering'
  else 'unsafe'
end as 'Status'
from Products

-- Q19
-- 取出2004年3月銷售額前五名的員工id及金額
select top 5 EmployeeID, sum(UnitPrice * Quantity * (1 - Discount)) as TotalPrice
from Orders join OrderDetails on Orders.OrderID = OrderDetails.OrderID
where OrderDate between '2004-03-01' and '2004-03-31'
group by EmployeeID
order by TotalPrice desc

-- Q20
-- 取得2003年平均每個月的訂單數
select avg(Cnt) as AvgOrderCnt
from (
  select count(OrderID) as Cnt
  from Orders
  where year(OrderDate) = '2003'
  group by month(OrderDate)
) as temp1

-- Q21
-- 取得各城市各分類的訂單數量
select ProductID, Products.CategoryID, CategoryName
into #benjamin_21_1
from Products join Categories on Products.CategoryID = Categories.CategoryID

select ShipCity, Orders.OrderID, ProductID
into #benjamin_21_2
from Orders join OrderDetails on Orders.OrderID = OrderDetails.OrderID

select ShipCity, CategoryID, count(OrderID) as Cnt
from #benjamin_21_1 join #benjamin_21_2 on #benjamin_21_1.ProductID = #benjamin_21_2.ProductID
group by ShipCity, CategoryID
order by ShipCity, CategoryID

drop table #benjamin_21_1
drop table #benjamin_21_2

-- Q21-2
-- 原來with是這樣用啊
with #benjamin_21_1 (ProductID, CategoryID, CategoryName)
as (
  select ProductID, Products.CategoryID, CategoryName
  from Products join Categories on Products.CategoryID = Categories.CategoryID
),
#benjamin_21_2 (ShipCity, OrderID, ProductID)
as (
  select ShipCity, Orders.OrderID, ProductID
  from Orders join OrderDetails on Orders.OrderID = OrderDetails.OrderID
)

select ShipCity, CategoryID, count(OrderID) as Cnt
from #benjamin_21_1 join #benjamin_21_2 on #benjamin_21_1.ProductID = #benjamin_21_2.ProductID
group by ShipCity, CategoryID
order by ShipCity, CategoryID

-- Q22
-- 寫log的trigger，和dynamoDB stream相似的東西
create trigger shippers_trigger on Shippers
  for insert, update, delete
as
  -- 更新=新增+刪除
  -- 新增
  -- 刪除
  if (select count(*) from inserted) != 0
  begin
    if (select count(*) from deleted) != 0
  begin
    insert into ShippersLog (Time, Operation, DelShipperID, DelCompanyName, DelPhone, InsShipperID, InsCompanyName, InsPhone)
    select getdate(), 'Update', deleted.ShipperID, deleted.CompanyName, deleted.Phone, inserted.ShipperID, inserted.CompanyName, inserted.Phone
    from inserted Join deleted on inserted.ShipperID = deleted.ShipperID
  end
  else
  begin
    insert into ShippersLog (Time, Operation, InsShipperID, InsCompanyName, InsPhone)
    select getdate(), 'Insert', inserted.ShipperID, inserted.CompanyName, inserted.Phone
    from inserted
  end
  end
  else if (select count(*) from deleted) != 0
  begin
    insert into ShippersLog (Time, Operation, DelShipperID, DelCompanyName, DelPhone)
    select getdate(), 'Delete', deleted.ShipperID, deleted.CompanyName, deleted.Phone
  from deleted
  end
go

-- Q23
-- 調薪
-- 超複雜，需要先加主管的薪水避免主管卡部屬

use NorthwindChinese;

-- 記錄階層(Hierarchy)的table，透過join自己的方式產生有所區別的資料
with Hierarchy (EmployeeID, ManagerID, Level) as
(
    (-- 在table空的狀態，第一次執行的內容
	select EmployeeID, ManagerID, 1 as Level
	from Employees
	where ManagerID is null
	-- 這行執行後，Hierarchy的內容產生Level 1的四筆資料
	union all -- 此情境必填，避免重複的資料產生
	-- 第一次執行時join對象是Level 1的四筆資料，產生Level 2的資料
	select Employees.EmployeeID, Employees.ManagerID, Level + 1
	-- 由於join的其中一方Hierarchy(自身)在過程中會持續增加資料，因此select不可以宣告例如Hierarchy.EmployeeID的欄位，會停不下來
	from Employees
	join Hierarchy
	    on Hierarchy.EmployeeID = Employees.ManagerID
	-- 第二次執行時，由於Hierarchy存在Level 1、2的資料，理論上會產生Level 2、3的資料(2重複)，但是因為有union all所以僅產生Level 3
	-- 以下省略，直到沒有新的資料(Level)為止
    )
)

-- 由於with宣告的table只能使用一次之後就會清除，重複利用需要再建立一次
-- 建立暫存table儲存階層對應現在的薪水
select Hierarchy.*, Salary
into #HierarchySalary
from Hierarchy join Employees on Hierarchy.EmployeeID = Employees.EmployeeID

-- 計算員工按業績調薪後的可能薪資寫入暫存table #RaisingInfo，不考慮主管薪水
select RaiseMember.*, Employees.Salary,
case -- 計算調薪後薪水
  when OrderCount >= 100 then
  case
    when Salary >= 50000 then Salary + 5000
    else cast(Salary * 1.1 as int)
  end
  when OrderCount >= 50 then
  case
    when Salary >= 100000 then Salary + 5000
    else cast(Salary * 1.05 as int)
  end
  else Salary
end as ExceptedSalary
into #RaisingInfo
from (
  select EmployeeID, count(OrderID) as OrderCount
  from Orders
  group by EmployeeID
  having count(OrderID) >= 50
) as RaiseMember
  join Employees on RaiseMember.EmployeeID = Employees.EmployeeID

-- 更新薪水的名單、順序
select #RaisingInfo.EmployeeID, ExceptedSalary, ManagerID, Level
from #RaisingInfo
  join #HierarchySalary on #RaisingInfo.EmployeeID = #HierarchySalary.EmployeeID
order by Level

-- 使用迴圈，按Level 1, 2, 3的順序更新暫存table #HierarchySalary的薪水資料
begin

  declare @nowLevel int
  declare @maxLevel int

  set @nowLevel = 1
  -- 取得最大Level數作為終止條件
  set @maxLevel = (select max(Level) from #HierarchySalary)

  while @nowLevel <= @maxLevel
  begin
    update #HierarchySalary
	set #HierarchySalary.Salary =
	case
      -- 如果沒有主管，調薪結果不變
	  when #HierarchySalary.ManagerID is null then #RaisingInfo.ExceptedSalary
	  -- 如果有主管且調薪後大於主管，調薪結果等同主管
	  when #RaisingInfo.ExceptedSalary > #HierarchySalary2.Salary then #HierarchySalary2.Salary
	  -- 如果有主管且調薪後小於等於主管，調薪結果不變
	  else #RaisingInfo.ExceptedSalary
	end
    -- 透過join #RaisingInfo限縮範圍為需要調薪的員工，join #HierarchySalary as #HierarchySalary2取得主管的薪資(在之前的迴圈已更新之後)
	from #HierarchySalary
	  inner join #RaisingInfo on #HierarchySalary.EmployeeID = #RaisingInfo.EmployeeID
	  left join #HierarchySalary as #HierarchySalary2 on #HierarchySalary.ManagerID = #HierarchySalary2.EmployeeID
	where #HierarchySalary.Level = @nowLevel

	set @nowLevel = @nowLevel + 1
  end
end

-- 確認更新薪水後暫存table的資料
select * from #HierarchySalary order by EmployeeID

-- 利用暫存table更新後的結果對Employees update
-- 不在迴圈更新而是在最後更新，好處是可以在確認更新內容無誤後再執行，避免Employees更新不正確需要回溯
update Employees
set Employees.Salary = #HierarchySalary.Salary
from Employees, #RaisingInfo, #HierarchySalary
where Employees.EmployeeID = #RaisingInfo.EmployeeID and #RaisingInfo.EmployeeID = #HierarchySalary.EmployeeID

-- 確認Employees異動結果
--select Employees.*
--from Employees, #RaisingInfo
--where Employees.EmployeeID = #RaisingInfo.EmployeeID

drop table #RaisingInfo
drop table #HierarchySalary

-- Q24
-- 新增欄位，並經過計算後更新資料
alter table Employees add Seniority int;
-- 新增欄位這種需要先設定好的部分需要使用go
-- 暫存table似乎不會有這種問題
go

update Employees
set Seniority = datediff(month, HireDate, '2004-12-31')
-- 驗證用
-- select EmployeeID, Seniority from Employees

-- Q25
-- 刪除停止販售的商品
delete from Products where Discontinued = 1
-- 驗證用
-- select ProductID from Products
