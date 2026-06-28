
/* Identify matches played between two specific teams (e.g.,India and South Africa) in 2024 and their result)*/

select * from dbo.T20I
where (Team1 = 'South Africa' and Team2 = 'India') or (Team1 = 'India' and Team2 = 'South Africa')
and YEAR(MatchDate) = 2024


/* Find the team with highest number of wins in 2024 and the total matches it won */

select top 1 Winner, Count(*) as Total_wins 
from T20I 
group by Winner 
order by Total_wins desc

/* Rank the teams based on the total numbers of wins in 2024 */

select Winner, Count(*) as Total_wins,
dense_rank() over ( order by Count(*) desc) as RankAssigned
from T20I 
where YEAR(MatchDate) = 2024 and Winner not in ('tied', 'no result')
group by Winner 
order by Total_wins desc

/* which team had the highest average winning margin (in runs), and what was the average margin? */

select top 1 Winner, avg(cast(left(Margin,CHARINDEX(' ',Margin) - 1) as int)) as Avg_Margin from dbo.T20I
where Margin like '%runs'
group by Winner
order by Avg_Margin desc

/* which team had the highest average winning margin (in wickets), and what was the average margin? */
select top 1 Winner, avg(cast(left(Margin,CHARINDEX(' ',Margin) - 1) as int)) as Avg_Margin from dbo.T20I
where Margin like '%wickets'
group by Winner
order by Avg_Margin desc;

/* List all mathces where the wining margin was greater than the average margin across all mathces */

with CTE_AvgMargin AS(
select avg(cast(left(Margin,CHARINDEX(' ',Margin) - 1) as int)) as Avg_OverallMargin from dbo.T20I
where Margin like '%runs')

select T.Team1,T.Team2,T.Winner,T.Margin from T20I T
left join CTE_AvgMargin A ON 1 = 1
where T.Margin like '%runs' and cast(left(Margin,CHARINDEX(' ',Margin) - 1) as int)> A.Avg_OverallMargin

/* Find the team with most wins when chasing a target (wins by wickets) */

Select Winner, wins_by_wickets from (
select Winner, Count(*) as wins_by_wickets, dense_rank() over (order by count(*) desc) as RankAssigned
from T20I
where Margin like '%wickets' and Winner not in ('tied','no result')
group by Winner)t
where RankAssigned = 1

/* Head-to-head record between two selected teams (e.g., England vs Australia)*/

declare @TeamA varchar(25) = 'England'
declare @TeamB varchar(25) = 'Australia'

select * 
from T20I
where (Team1 = @TeamA and Team2 = @TeamB) or (Team1 = @TeamB and Team2 = @TeamA)

/* Indentify the month in 2024 with the hgihest number of T20I matches played */

WITH matchtotal AS (
    SELECT Team, COUNT(*) AS MatchPlayed
    FROM (
        SELECT Team1 AS Team
        FROM T20I
        WHERE YEAR(MatchDate) = 2024

        UNION ALL

        SELECT Team2 AS Team
        FROM T20I
        WHERE YEAR(MatchDate) = 2024
    ) t
    GROUP BY Team
),
matchwin AS (
    SELECT
        Winner AS Team,
        COUNT(*) AS MatchWon
    FROM T20I
    WHERE YEAR(MatchDate) = 2024 and Winner not in ('tied','no result')
      AND Winner IS NOT NULL
    GROUP BY Winner
)
SELECT
    t.Team,
    t.MatchPlayed,
    ISNULL(w.MatchWon, 0) AS MatchWon,
    cast((CAST(ISNULL(w.MatchWon, 0) as decimal(5,2)) / t.MatchPlayed) as decimal(10,4))  AS WinRate
FROM matchtotal t
LEFT JOIN matchwin w
    ON t.Team = w.Team
ORDER BY WinRate DESC;


/* Indentify the most successful team at each ground) */
with mostwins as(
select Ground, Max(num_wins) as most_wins from 
(select Winner, Ground, count(*) as num_wins from T20I

group by Winner, Ground
)t
group by Ground),

 Countwins as(
select Winner, Ground, count(*) as num_wins from T20I
where Winner not in ('tied','no result')
group by Winner, Ground)

select c.Ground,c.Winner,m.most_wins from
mostwins m
inner join Countwins c on m.most_wins = c.num_wins and m.Ground = c.Ground
order by Ground asc

