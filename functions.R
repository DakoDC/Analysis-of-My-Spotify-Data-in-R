

################################## Functions ###################################


# convert milliseconds to hours
ms.to.hours.f <- function(ms) round(ms/60000/60,2)




# returns the dataframe with only rows with at least one of the specified genres
# ex. genres = "pop"      -> keeps: "pop", "j-pop", "k-pop", "pop rock",...
# es. genres = "rock , j" -> keeps: "rock","punk rock", "j-rock", "j-pop",...

genres.selection.f <- function(df,  # df with the "genre" column
                               genres.orig, # list of genres
                               keep = TRUE # # removes(FALSE) / keeps(TRUE) the songs of the specified genres
                               ){
  # turn the genres in lowercase
  genres.orig = tolower(genres.orig)
  
  # remove eventual "-" from the genres given
  genres = gsub("-", " ", genres.orig)
  
  # create list of all the words in each song's genre
  a <- str_split(df$genre, ", ")
  for(i in 1:length(a)){
    a[[i]] = unlist(str_split( gsub("-", " ", a[[i]] ), " "))
  }
  
  # set variables
  idx = FALSE
  is.genre = FALSE
  
  for(j in 1:length(genres)){ # loops for every genre given
    # reset variable with each genre
    idx.gen = TRUE
    
    for(g in str_split_1(genres[j], " ")){ # loops for every word in the genre
      for(i in 1:length(a)){ # loops for every row in the original dataframe
        is.genre[i] = g %in% a[[i]] # list, TRUE(if the i-th song has the word g), FALSE otherwise
      }
      idx.gen = is.genre & idx.gen # keeps only the songs that have all the words (g), up to that point of the loop
    }
    
    is.genre = grepl(genres.orig[j], df$genre) # list, TRUE(if the i-th song has the j-th genre in the dataframe's genre string), FALSE otherwise
    idx.gen <- is.genre & idx.gen # combines the 2 index lists and keeps only if both are TRUE
    
    idx <- idx.gen | idx # list, TRUE if the song has the all the j-th genres up to that point of the loop
    
    
  }
  if(keep) df[which(idx),] # returns the df with only the rows that have at least one of the specified genres
  else df[-which(idx),] # removes the rows that have at least one of the specified genres
}





############ Plot Functions ############

# General barplot given a dataframe
barplot.f <- function(df, # dataframe with name and value for each observation 
                      axis.lab, # labels of the plot axis
                      a = 1,
                      b = 20, # the plot will show the top a:b observation
                      ms.to.hours = FALSE, # if TRUE converts the values from milliseconds to hours
                      left.value = TRUE, # if TRUE keeps the value of each bar to the left, if FALSE to the roght
                      top = TRUE, # if TRUE uses the highest values in the ordered dataframe, if FALSE uses the bottom values
                      label.wrap = TRUE # if TRUE wraps longer strings to the next line
                      ){
  df = df[order(df[,2], decreasing = top),][a:b,] # orders the dataframe
  name <- df[,1] # objects column
  value <- df[,2] # values column
  
  # convert milliseconds to hours
  if(ms.to.hours) value <- ms.to.hours.f(value)
  
  
  idx = which(duplicated(name)) # check for duplicates
  while(length(idx) > 0){ # while there are no duplicates
    idx = which(duplicated(name)) # check for duplicates
    name[idx] = paste0("*",name[idx]) # adds * to duplicates
  }
  n = nrow(df)
  ggplot(df, aes(x = value, y = reorder(name,value) )) +
    geom_bar(aes(fill = 1:n), # creates barplot
             stat = "identity", width = 0.8) +
    
    {if(left.value)
      geom_text(aes(label = value), # creates the value's labels
                vjust = 0.4,hjust = 1.1, color = "white")
    else
      geom_text(aes(label = value, color = 1:n), # creates the value's labels
                vjust = 0.4,hjust = -0.1)
    } +
    theme(legend.position = "None" ) + # removes legend from the plot
    scale_fill_gradient(low = "navy", high = "steelblue2") + # colors of the observations
    {if(label.wrap) scale_y_discrete(labels = label_wrap_gen(30)) } + # ends lines automatically after 30 characters
    labs(x = axis.lab[2] , y = axis.lab[1]) # modifies axis labels
}





# Given a df returns the df adapted for a stacked barplot
# It will order the types based on the order of the df's columns
# (Used for the stack.barplot.f function)
stack.df.f <- function(df){
  groups.name = df[,1]   # Df given in input:
  n = nrow(df)           #  group name | values type1 | values type2 | ...
  J = ncol(df)           #     name1   |     23       |       34     | ...
  values = df[,2]        #     name2   |     4        |       23     | ...
  type = rep(1,n)        #     name3   |     18       |       9      | ...
  
  for(j in 3:J){ # from the third column of the df
    values = c(values,df[,j])
    type = c(type, rep(j-1,n))
  }
  
  data.frame(
    group = rep(df[,1],J-1),
    type = type,
    value = values
  )
}




# creates a general stacked barplot
stack.barplot.f <- function(top.df, # ordered df in the format needed for the stack.df.f function above
                            axis.lab,
                            ms.to.hours = FALSE,
                            last.percentage = TRUE
                            ){
  df <- stack.df.f(top.df)
  
  # convert milliseconds to hours
  if(ms.to.hours){
    df$value <- ms.to.hours.f(df$value)
    top.df[,-1] <- ms.to.hours.f(top.df[,-1])
    }
  
  group = df$group
  
  J = ncol(top.df)
  n = nrow(top.df)
  
  
  idx = which(duplicated(group[1:n]))   # check for duplicates
  while(length(idx) > 0){               # while there are no duplicates
    idx = which(duplicated(group))      # check for duplicates
    group[idx] = paste0("*",group[idx]) # adds * to duplicates
  }
  
  
  tot.ms <- data.frame( total = apply(top.df[,-1], 1, sum))
  tot.ms = tot.ms$total

  
  percentages <- apply(top.df[,-1], 2, function(col) paste0( round( col / tot.ms * 100, 2), "%" ))
  sapply(top.df[,-1], function(col) paste0( round( col / tot.ms * 100, 2), "%" ))
  
  if(last.percentage) percentages = percentages[,-(J-1)] # if TRUE, removes the percentage of the last bar in every group 
  
  
  ggplot(df, aes(x = value, y = reorder(group,value))) +
    geom_bar(position = "stack", stat = "identity", aes(fill = type)) +
    
    # percentages
    geom_text(aes( label = c(percentages,rep("",n))),
              vjust = 0.4,hjust = 1.1, color = "white") +
    # total hours
    geom_text(aes(x = rep(tot.ms,J-1), label = rep(tot.ms[1:n], J-1)),
              vjust = 0.4,hjust = -0.1, color = "steelblue3") +
    
    theme(legend.position = "None") +
    scale_fill_gradient(low = "steelblue4", high = "steelblue3") +
    labs(x = axis.lab[1] , y = axis.lab[2])
  
}


