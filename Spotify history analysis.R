

############################### SPOTIFY ANALYSIS ###############################
# This project is meant to be an exploratory analysis of my full Spotify history of songs played,
# with a code made to be accesible and reproducible to everyone, even with basic knowledge of R.
# I'll also use the Spotify API by getting the genres of each song listened to gain
# more interesting insights in the analysis by comparing their differencies.

# At the end of the code there are a few useful lines to get a look at the informations of specific songs


rm(list = ls())


######################### Data preparation and cleaning ######################## 
# If the packages are not yet installed use:
# install.packages("rjson")
# install.packages("ggplot2")
# install.packages("tidyverse")
# install.packages("spotifyr")

# load packages
library(rjson)     # read the spotify streaming history files
library(ggplot2)   # make plots
library(tidyverse) # useful functions
library(spotifyr)  # Spotify API functions

# load functions
source("functions.R") 

# get the names of the json spotify files by giving the path of the folder that contains them
files.name.raw <- list.files("Spotify Extended Streaming History",
                             pattern = "*.json", full.names = TRUE)

# remove the streaming video history files
files.name = files.name.raw[-grep("Video",files.name.raw)]

# total number of files 
length(files.name)

# read the files and store them in a list
raw.data.list <- lapply(
  files.name,
  function(file){
    print(file)
    fromJSON(file = file)}
)
# create a single list with all the data
raw.data <- unlist(raw.data.list, recursive = FALSE) # strips the first layer of the list

# remove songs with NULL data
problems = which( sapply(raw.data, function(song) is.null(song[[8]])) ) # songs with NULL values
data = raw.data[-problems] # cleaned data


# total number of songs listened
ndata <- length(data); ndata

# convert the data to a dataframe
data.df.raw <- data.frame( do.call(rbind,data) )

# column names
data.names = c(         #      For each song played:
  "timestamp",          #  1 - Date and time it was played
  "username",           #  2 - Username of the user who played it
  "platform",           #  3 - Device used
  "ms_played",          #  4 - Duration of playtime in milliseconds (ms)
  "country",            #  5 - Country it was played in
  "ip",                 #  6 - IP address
  "user",               #  7 - User
  "song",               #  8 - Song name
  "artist",             #  9 - Artist name
  "album",              # 10 - Album name
  "song_id",            # 11 - Song Id
  "episode_name",       # 12 - Episode name
  "episodeShow_name",   # 13 - Episode show name
  "episode_uri",        # 14 - Episode id
  "reason_start",       # 15 - Reason it started playing
  "reason_end",         # 16 - Reason it stopped playing
  "shuffle",            # 17 - Was it in Shuffle mode? (TRUE/FALSE) 
  "skip",               # 18 - Was it skipped? (TRUE/FALSE)
  "offline",            # 19 - Was it listened while offline? (TRUE/FALSE)
  "offline_timestamp",  # 20 - Timestamp in a different format
  "incognito"           # 21 - Was it played while in incognito mode? (TRUE/FALSE)
)

# give appropriate names to the df columns
colnames(data.df.raw) <- data.names

# remove data columns I'm not going to cover for better readability
data.df = data.df.raw[,c(1,4,8,9,10,11)]

# visualize the dataframe
head(data.df)



# Unlisting the dataframe's columns
data.df$song # I can see it's a list, and so are most of the other columns
data.df <- data.frame( sapply(data.df, unlist) )
data.df$song # format wanted

# clean song IDs
data.df$song_id <- str_remove(data.df$song_id,"spotify:track:")

# make milliseconds numerical values instead of strings
data.df$ms_played <- as.numeric(data.df$ms_played) 






############################# Exploratory analysis #############################


#### Create dataframe of the songs ####


# dataframe of the songs with the amount of milliseconds each song was listened to
# ( ordered by song_id to avoid problems with songs with the same name )
songs.df <- aggregate(ms_played ~ artist + song + song_id, data.df, sum)

# add the total times each song was played
songs.df$Freq = data.frame(table(data.df$song_id))$Freq

# order the dataframe for more clarity
songs.df = songs.df[c("song","song_id","ms_played","Freq","artist")]
view(songs.df)

# plot of the most played songs
barplot.f(
  df = songs.df[c("song","Freq")],
  axis.lab = c("Songs","Times listened"),
  a = 1,
  b = 20,
  ms.to.hours = FALSE
)

# plot of the most listened songs
barplot.f(
  df = songs.df[c("song","ms_played")],
  axis.lab = c("Songs","Hours played"),
  a = 1,
  b = 20,
  ms.to.hours = TRUE
)

nsongs = nrow(songs.df); nsongs # total number of different songs played
ndata/nsongs # mean of the times i listened to each song
ms.to.hours.f(sum(songs.df$ms_played))/24 # days spent listening to music


# plot of all the songs duration of listening in seconds 
ms.ordered <- data.df$ms_played[order(data.df$ms_played)]
barplot(ms.ordered / 1000) # in seconds
abline(h = 30, col = "blue") # marks the point where a song is considere or not skipped (30 sec)








#### Get the songs' genres ####

# Spotify associates every song's genres with its artist's genres so all the songs of an artist will have the same genres.
# I'll use the Spotify API to get the genres of each artist.

# replace the 'x' with your own IDs: (check how in the README file)
Sys.setenv(SPOTIFY_CLIENT_ID = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
Sys.setenv(SPOTIFY_CLIENT_SECRET = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")

# There is a limit of about 5000 operations a day
# so it may take more than a single day to get all the needed data

# Get access token for the spotify API
access_token <- get_spotify_access_token()

# Get track details, including each artist's ID
songs.details <- vector("list", nsongs) # initialize the vector
for(i in 1:nsongs){
  songs.details[[i]] <- get_tracks(songs.df$song_id[i]) 
  
  if(i %% 100 == 0) print(i)
}
# if there are more than 5000 songs, you can continue the loop from where it stopped the previous day

# extract and add the artists IDs to the songs dataframe
songs.df$artist_id <- sapply(songs.details, function(song) song$artists[[1]]$id[1])

# dataframe of artist IDs and their genres 
artists.details = vector("list", nsongs) # initialize the vector
for(i in 1:nsongs){
  artists.details[[i]] = get_artist(songs.df$artist_id[i])
  
  if(i %% 100 == 0) print(i)
} # limit of ~5000 a day

# add genre column to each song in the dataframe
songs.df$genre <- sapply(artists.details, function(artist) paste(artist$genres, collapse = ", "))
songs.df$genre[songs.df$genre == ""] <- "* Not found *" # artists without specified genres

view(songs.df)



# dataframe with the artists and their genres
artist.genre.df.raw <- distinct( songs.df[c("artist","artist_id","genre")] )

# remove eventual duplicated artists with more than 1 list of genres associated
artist.genre.df <- artist.genre.df.raw[!duplicated(artist.genre.df.raw$artist_id), ]
nrow(artist.genre.df) # total artists listened

# dataframe with the amount of songs of each specific genre
genres.df <- data.frame( table(
  unlist(str_split( artist.genre.df$genre, pattern = ", " ))
))
colnames(genres.df)[1] = "genre"


# plot of the most popular genres in the data
barplot.f(
  df = genres.df[-which(genres.df == "* Not found *"), ], # genres without the amount of genres not found
  axis.lab = c("Genre","Times played"),
  1,20,
  ms.to.hours = FALSE
)
# This is how Spotify separates genres, some of the names look very similar without
# a clear difference on how they should sound differently.

# Which is why I'm going to group up the genres into macro categories,
# so instead of having, for example: italian pop, dance pop, k-pop, classic italian pop,...
# There is going to be the "pop" genre to group them all up.



# plot of the most listened songs with at least one of the specified genres
barplot.f(
  df = genres.selection.f(songs.df, c("dance","edm","electro","house"), keep = TRUE)[c("song","ms_played")],
  axis.lab = c("Songs","Hours played"),
  a = 1,
  b = 20,
  ms.to.hours = TRUE
)






################################ Genres analysis ###############################

# grouping up similar genres in macro-categories (may have genres with more than one macro-categorie,
# es. a song with the genre "latin pop" will be counted both in the "latin" genre and the "pop" genre 

# list of the genres I'm going to use
# (add or change the genres at will in every part of the code)
macro.genres <- list(
  "blues", "folk", "funk", "hip hop", "indie", "italian", "jazz","latin", "lo-fi", # will look for all the songs with the specified word in them
  "metal", "pop", "punk", "r&b", "rap", "reggae", "rock", "soul", "trap",
  c("japanese","j","anime","otacore","visual kei"), # c(...) will look for songs with at least one one of the genres
  c("dance","edm","electro","house"), c("korean","k") ) # for genres like k-pop, k-rap,... the string "k" will look for both of them


# dataframe of each macrogenre and its total milliseconds listened
macro.genres.df <- data.frame(
  genre = unlist( lapply(macro.genres, paste, collapse = ", ") ),
  # for each genre in macro.genres it sums the milliseconds from all the songs of that genre
  ms_played = unlist( lapply(macro.genres, function(x) sum( genres.selection.f(songs.df, x)$ms_played )) )
)


# Plot of the total hours played of each genre
barplot.f(df = macro.genres.df,
          axis.lab = c("Genre","Hours played"),
          1,10,
          ms.to.hours = TRUE,
          left.value = TRUE
)





# genres to use in the violin plot
viol.genres <- list("pop","rock","rap","hip hop","lo-fi","indie","italian",
                    c("j","anime","otacore","visual kei"),c("k","korean"),
                    c("dance","edm","electro","house"),"hip hop")

# dataframe of the total playtime of each song for each of the chosen genres
viol.df <- data.frame()
for(gen in viol.genres){ # for each genre, creates a dataframe with the milliseconds played of each one
  viol.df <- rbind( # binds the dataframe of the genres till that moment with the df of the next genre
    viol.df,
    data.frame(
      genre = paste(gen,collapse = ", "), 
      
      # avoiding songs with less than 30 times played, to focus on the songs listened more regurlarly
      ms_played = genres.selection.f(songs.df[ which(songs.df$Freq > 30), ] , gen)$ms_played)
  )
}

# plot of the playtime distribution among the most listened genres
# (ignoring the outliers to have a better view of the distributions)


ggplot(viol.df,
       aes(x = reorder(genre,ms_played),
           y = ms.to.hours.f(ms_played),
           fill = reorder(genre,ms_played),
           color = reorder(genre,ms_played)
           )
       ) +
  
  geom_violin(alpha = 0.4) +
  geom_jitter(size = 0.8) +
  
  
  scale_x_discrete(labels = label_wrap_gen(15)) +
  scale_fill_manual(values = colorRampPalette(c("navy","steelblue1","purple2"))(length(viol.genres))) +
  scale_color_manual(values = colorRampPalette(c("navy","steelblue1","purple2"))(length(viol.genres))) +
  
  labs(x = "Genre", y = "Hours played") +
  theme(legend.position = "None" ) +
  coord_cartesian(ylim = c(0,30)) + # ignoring the outliers
  scale_y_continuous(breaks = seq(0,30,4))




################################ Skips analysis ################################ 

# Instead of using the skips values given in the files data
# (Not sure of the criteria that Spotify used)
# I'm going to consider a song skipped if it stopped playing before 30 seconds


# number of songs skipped (less than 30s of playtime)
nskips <- sum(data.df$ms_played < 30000); nskips
nskips/ndata # percentage of skipped songs 

ms.ordered.df <- data.frame(
  songs = 1:ndata,
  ms_played = data.df$ms_played[order(data.df$ms_played)])

# Plot of the distribution of the playing time of each song played
ggplot(ms.ordered.df, aes(x = songs, y = ms_played / 1000)) +
  geom_violin(alpha = 0.7, fill = "navy") +
  geom_line(lwd = 1) +
  
  annotate("segment", x = 0, xend = 100000, y = 30, yend = 30, col = "orange", lwd = 1) +
  annotate("segment", x = 25000, xend = 75000, y = 100, yend = 100, col = "purple", lwd = 1) +
  annotate("segment", x = 25000, xend = 75000, y = 275, yend = 275, col = "purple", lwd = 1) +
  
  scale_y_continuous(breaks = seq(0,max(ms.ordered.df$ms_played),50)) +
  labs(x = "Number of Songs", y = "Seconds played")

# dataframe of all songs listened and if they were skipped (less than 30 seconds of playtime)
is.skip.df <- data.frame(
  song_id = data.df$song_id,
  song = data.df$song,
  skips = data.df$ms_played < 30000
)

# add the total skips of each songs to the songs.df dataframe
songs.df$skips <- aggregate(skips ~ song_id, is.skip.df, sum)$skips

# add the percentage of skips of each songs to the songs.df dataframe
songs.df$skip_perc = round(songs.df$skips/songs.df$Freq, 3)


# keep only the songs with a minimum number of times played (to avoid songs only listened a few times)
top.skips.df <- songs.df[ which(songs.df$Freq > 125),]

# plot of the most skipped songs
barplot.f(
  df = top.skips.df[c("song", "skip_perc")],
  axis.lab = c("Songs","Skip percentage" ),
  1,20,
  ms.to.hours = FALSE
)

# plot of the least skipped songs
barplot.f(
  df = top.skips.df[c("song", "skip_perc")],
  axis.lab = c("Songs","Skip percentage" ),
  1,20,
  ms.to.hours = FALSE,
  top = FALSE
)



# remove the songs of the specified genres
skips.genre.df <- genres.selection.f(songs.df, "lo-fi", keep = FALSE)
# keep = TRUE: keeps only the songs of the specified genres
# keep = FALSE: removes the songs of the specified genres

# keep only the songs with a minimum number of times played
skips.genre.df.cut <- skips.genre.df[ which(skips.genre.df$Freq > 125),]

# plot of the most skipped songs without/with only, the specified genres
barplot.f(
  df = skips.genre.df.cut[c("song", "skip_perc")],
  axis.lab = c("Songs","Skip percentage" ),
  1,20
)

# plot of the least skipped songs without the specified genres
barplot.f(
  df = skips.genre.df.cut[c("song", "skip_perc")],
  axis.lab = c("Songs","Skip percentage" ),
  1,20,
  top = FALSE # FALSE: returns the top from bottom to up
)







############################### Artists analysis ############################### 

# dataframe with the total milliseconds played for each artist
artists.df <- aggregate(ms_played ~ genre + artist + artist_id, songs.df, sum)
view(artists.df)

# plot of the most listened artists
barplot.f(
  df = artists.df[c("artist","ms_played")],
  axis.lab = c("Artists", "Hours played"),
  1,15,
  ms.to.hours = TRUE
)

# add a column with the total milliseconds listened of the most listened song of each artist
artists.df$ms_top_song <- aggregate( ms_played ~ artist + artist_id, songs.df, max )$ms_played

# dataframe with the name of the most listened song for every artist
# (If an artist has more than 1 song with the most milliseconds they are in separate rows)
artists.top_song.df <- merge(
  artists.df, songs.df[c("artist","artist_id","ms_played","song","song_id")],
  by.x = c("artist","artist_id","ms_top_song"), by.y = c("artist","artist_id","ms_played"), # to avoid renaming colums
  sort = FALSE ) # to keep the dataframe ordered by artist_id instead of by artist

# add a column of the difference between the top song's milliseconds and the total artist's milliseconds
artists.top_song.df$diff = artists.top_song.df$ms_played - artists.top_song.df$ms_top_song

# add a column with a string of both the artist's and song's name
artists.top_song.df$artist_song <- apply(artists.top_song.df[c("artist","song")], 1, paste0, collapse = "\n")


# adapt and order the dataframe to work with the stack.df.f function
top.stack.artists.df <- artists.top_song.df[c("artist_song","ms_top_song","diff")] [order(artists.top_song.df$ms_played, decreasing = TRUE), ]
head(top.stack.artists.df)

# plot of the top listened artists and their most listened song 
stack.barplot.f(top.df = top.stack.artists.df[1:20,],
                axis.lab = c("Hours Played","Artist - Song"),
                ms.to.hours = TRUE
)







################################ Albums analysis ############################### 

# add a column to thee songs dataframe with the albums' names for each song
songs.df$album <- sapply(songs.details, function(song) song$album.name) # for each track, the correspondent artist's id

# add a column to the songs dataframe with the albums' IDs for each song
songs.df$album_id <- sapply(songs.details, function(song) song$album.id) # for each track, the correspondent artist's id



# dataframe of the albums with their total milliseconds played
albums.df <- aggregate(ms_played ~ album + album_id, songs.df, sum)

# dataframe, for each album, a row with each artist in it
albums.artist.df <- distinct( merge(albums.df, songs.df[c("album","album_id","artist")], by = c("album_id","album")) )

# add the artists to the albums dataframe
# albums.df$artist <- aggregate( artist ~ ms_played + album + album_id, albums.artist.df, paste, collapse = ", ")$artist
albums.df$artist <- aggregate( artist ~ ms_played + album + album_id, albums.artist.df, list)$artist
view(albums.df) # structure of the dataframe, at the 50th row there is an example of an album with multiple artist


# This nect part is only for the plot visualisation
# for each album, if one has more than 1 artists it rewrites the list of artists in a more readble string
albums.artists.cut <- sapply(
  albums.df$artist,
  function(x){ # x: the list of artists of each album
    n = length(x)
    if(n <= 1) return(x)                                             # albums with 1 artist
    if(n > 1 & n <=3) return( paste(x, collapse = ", ") )            # albums with 2 or 3 artists
    return( paste0( paste0(x[-(4:n)], collapse = ", "), ", ..." ) )  # albums with more than 3 artists
  }
)
albums.artists.cut[c(1,41,50)] # examples of all 3 kinds of artists lists

# dataframe adapted for the plot
top.albums.df <- data.frame(
  album_artist = paste0(albums.df$album,"\n", albums.artists.cut),
  ms_played = albums.df$ms_played
)


# plot of the top albums played 
barplot.f(
  df = top.albums.df,
  axis.lab = c("Albums - Artists","Hours played"),
  1,15,
  ms.to.hours = TRUE,
  label.wrap = FALSE
)







############################## Timestamps analysis ############################## 

# get timestamps in year-month-day format
timestamps <- strptime(data.df$timestamp, format="%Y-%m-%dT%H:%M:%S")

# timestamps in the format: year-month-day
time.ymd <- as.Date(timestamps,"%Y-%m-%d")




#####  Daily analysis #### 

# dataframe of each song's milliseconds played and the day it was played
ymd.df.raw <- data.frame(
  timestamp = time.ymd,
  ms_played = ms.to.hours.f(data.df$ms_played) # transform to hours for better readability
)

# total hours played of each day
ymd.df <- aggregate(ms_played ~ timestamp, ymd.df.raw, sum) # ms.daily.df

# first look at the milliseconds of each day total hours listened
ggplot(ymd.df, aes(x = timestamp, y = ms_played)) +
  geom_bar(stat = "identity") +
  labs(x = "Year", y = "Hours played")


# days with the most hours played
ymd.df[order(ymd.df$ms_played, decreasing = TRUE),][1:10,]



############ Monthly analysis ############  

# total hours played in each month
ym.df <- aggregate(ms_played ~ format(time.ymd,"%m") + format(time.ymd,"%Y") , ymd.df.raw, sum)
colnames(ym.df)[c(1,2)] = c("month","year")

# months labels
months.lab.list = c("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
months.lab <- factor(months.lab.list, levels = months.lab.list)

# substitute the months labels from numeric to their names' abbreviation
ym.df$month <- months.lab[as.numeric(ym.df$month)]

# months with the most hours played
ym.df[ order(ym.df$ms_played, decreasing = TRUE), ][1:10,]

# check if all the years have music played in all 12 month
months.each.year <- table(ym.df$year)

# years with all music listened in every months
months.each.full.year <- months.each.year[ months.each.year == 12 ]
# remove the eventual years with less than 12 months of music played
ym.df.full = ym.df[which(ym.df$year %in% names(months.each.full.year)), ]


# plot of the total hours listened every month of each year
ggplot(ym.df, aes(x = month, y = ms_played, group = year, col = year)) + # , colour = year
  geom_line(lwd = 0.8) +
  labs(x = "Month", y = "Hours played") +
  scale_color_manual(values = colorRampPalette(c("purple1","orange","navy"))(length(months.each.year))) 


# plot of the milliseconds listened every month of each year
ggplot(ym.df.full, aes(x = rep(months.lab, nrow(ym.df.full)/12), y = ms_played, group = year, colour = year)) +
  geom_line(lwd = 0.8) +
  labs(x = "Month", y = "Hours played") + 
  scale_color_manual(values = colorRampPalette(c("purple1","orange","navy"))(length( months.each.full.year)) )  

# mean of the months 
month.mean.df <- aggregate(ms_played ~ month, ym.df.full, mean)



# plot comparison of the ms of each year and their mean
ggplot() +
  geom_line(data = ym.df.full,
            aes(x = rep(months.lab, nrow(ym.df.full)/12), y = ms_played, group = year, colour = year), lwd = 0.8) +
  geom_line(data = month.mean.df, aes(x = month, y = ms_played, group = 1), lwd = 1, lty = 2,col = "black") +
  labs(x = "Month", y = "Hours played") +
  scale_color_manual(values = colorRampPalette(c("purple1","orange","navy"))(length( months.each.full.year)) )  



month.days <- c(31,28,31,30,31,30,31,31,30,31,30,31) # days in each month (not counting leap years)
mean(month.mean.df$ms_played) # mean hours of listening each month
mean(month.mean.df$ms_played/month.days) # mean hours of listening each day
sum(month.mean.df$ms_played)/24 # each year, about 41.6 days are spent playing music




######################### Song's release date analysis ######################### 

# list of the year of release of each song
years.release <- format(
  as.Date( sapply(songs.details, function(song) song$album.release_date), format = "%Y"),
  format = "%Y")

# add the year of release column to the songs dataframe
songs.df$release <- as.numeric(years.release)

# total milliseconds listened from songs released in each year
release.df <- aggregate(ms_played ~ release, songs.df, sum)

# plot of the total hours listened from songs released in each year
ggplot(release.df, aes(x = release, y = ms.to.hours.f(ms_played))) +
  geom_bar(stat = "identity", width = 1, fill = "steelblue4", color = "gray25") +
  
  scale_x_continuous(breaks = seq(release.df$release[1], tail(release.df$release, 1),by = 4)) +
  labs(x = "Year" , y = "Hours played")



### Add genre ###

# genres to find the distribution for
genre.release = "Pop"

# removes/keeps the songs of the specified genres
release.genre.df.raw <- aggregate(
  ms_played ~ release,
  genres.selection.f(songs.df, c(genre.release), keep = TRUE), # songs of the specified genres
  sum
  )

# add the eventual years where there aren't songs listened of the chosen genres 
release.genre.df <- merge(release.df["release"], release.genre.df.raw, by = "release", all.x = TRUE)
release.genre.df[ is.na(release.genre.df) ] <- 0 # replaces NA with 0

# dataframe for the comparison plot
release.comparison.df <- data.frame(
  release = rep(release.df$release,2),
  ms_played = c( release.df$ms_played - release.genre.df$ms_played, release.genre.df$ms_played ),
  type = c( rep('1',nrow(release.df)), rep('2',nrow(release.genre.df)))
)

# plot of the comparison between all the songs and the ones specified by the genres
ggplot(release.comparison.df, aes(x = release, y = ms.to.hours.f(ms_played), fill = type, color = type )) +
  geom_bar(stat = "identity", width = 1) +
  
  scale_x_continuous(breaks = seq(release.comparison.df$release[1], tail(release.comparison.df$release, 1),by = 4)) +
  scale_fill_manual(values = c("steelblue4","steelblue1"), labels = c("Total", genre.release)) +
  scale_color_manual(values = c("gray25","gray85"), guide=FALSE) +
  theme(legend.position = c(0.1, 0.85)) +
  labs(x = "Year" , y = "Hours played", fill = "Genre")



########################## Hours of the day analysis ########################### 

# timestamps in the format: hour-minute-second
time.hms <- format(timestamps,"%H:%M:%S")

# timestamps in the format: hour
time.h <- format(timestamps, "%H")




# dataframe of each song's milliseconds played and the day it was played
time.h.df.raw <- data.frame(
  song_id = data.df$song_id,
  hour = time.h,
  ms_played = data.df$ms_played
)

# compacts the dataframe, sums observations' milliseconds with the same song_id and played at the same hour
time.h.songs.df <- aggregate(ms_played ~ hour + song_id, time.h.df.raw, sum)

# add the genre of each song
time.h.df <- merge(time.h.songs.df, songs.df[c("song_id","genre")], by = "song_id", all.x = TRUE)

# dataframe of the total milliseconds played at each hour of the day
hours.df <- aggregate(ms_played ~ hour, time.h.df, sum)
hours.df

# plot of the total hours played at each hour of the day
ggplot(hours.df, aes(x = hour, y = ms.to.hours.f(ms_played))) +
  geom_bar(stat = "identity", width = 1, fill = "steelblue4", color = "gray25") +
  labs(x = "Hour of the day", y = "Hours played")



# genres to get the comparison for
genre.hours = "Lo-fi"

# dataframe of the total milliseconds played at each hour of the day
hours.genres.df.raw <- aggregate(ms_played ~ hour,
                                 genres.selection.f(time.h.df, genre.hours, keep = TRUE),
                                 sum)

# adds eventual hours of the day without songs played of the specified genres
hours.genres.df <- merge(hours.df["hour"], hours.genres.df.raw, by = "hour", all.x = TRUE)
hours.genres.df[is.na(hours.genres.df)] <- 0 # replaces NA with 0


# dataframe for the comparison plot
hours.comparison.df <- data.frame(
  hour = rep(hours.df$hour,2),
  ms_played = c( hours.df$ms_played - hours.genres.df$ms_played, hours.genres.df$ms_played ),
  type = c( rep('1',nrow(hours.df)), rep('2',nrow(hours.genres.df)))
)

# plot of the comparison between all the songs and the ones specified by the genres
ggplot(hours.comparison.df, aes(x = hour, y = ms.to.hours.f(ms_played), fill = type, color = type )) +
  geom_bar(stat = "identity", width = 1) +
  
  scale_fill_manual(values = c("steelblue4","steelblue1"), labels = c("Total", genre.hours)) +
  scale_color_manual(values = c("gray25","gray85"), guide=FALSE) +
  theme(legend.position = c(0.1, 0.85)) +
  labs(x = "Hour of the day" , y = "Hours played", fill = "Genre")



# adds column of the percentage of milliseconds played of the specified genres over the total 
hours.genres.df$perc <- hours.genres.df$ms_played / hours.df$ms_played

# Plot of the hours of the day in which the specified genre is
# listened the most in percentage compared to the others.

# The line refers to the mean of the hours
ggplot(hours.genres.df, aes(x = hour, y = perc)) +
  geom_bar(stat = "identity", width = 1, fill = "steelblue4", color = "gray25") +
  geom_abline(slope = 0, intercept = mean(hours.genres.df$perc), col = "navy", lwd = 0.8) + # mean
  
  labs(x = "Hour of the day", y = "Percentage of the hours played")
  






#### Search for song's Informations ####
# useful at any point of the code to check for a specific song's attributes

# search by song name (case sensitive)
songs.df[which(songs.df$song == "Demons"),]

# search by artist name (case sensitive)
songs.df[which(songs.df$artist == "Ed Sheeran"),]

# search by genre (case sensitive)
genres.selection.f(songs.df, "pop")






