# Actions for ScoreAggregation package

## PersonalPreStatistics

```
personal-pre-statistics.rb
```

## PersonalStatistics

```
echo "| Deviaion | `cat {$I[2]}` |" | cat {$I[1]} - > {$O[1]}
```

## PersonalBarGraph

```
personal-bar-graph.sh
```

## TotalMean

```
total-mean.rb > {$O[1]}
```

## TotalStatistics

```
total-statistics.rb
```

## MeanSummary

```
mean-summary.rb > {$O[1]}
```

## HistgramGraph

```
histgram-graph.sh
```

## MD2HTML

```
kramdown {$I[1]} > {$O[1]}
```

## ApplyTemplate

```
apply-template.rb > {$O[1]}
```

