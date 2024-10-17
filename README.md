# Analysis of My Spotify Data in R

This project is meant to be an exploratory analysis of my full Spotify history of songs played, with a code made to be accesible and reproducible to everyone, even with basic knowledge of R.  
I'll also use the Spotify API by getting the genres of each song listened to gain more interesting insights in the analysis by comparing their differencies.  



# Index

[How to get your spotify history files](#how-to-get-your-spotify-history-files)  
[Data Preparation and Cleaning](#data-preparation-and-cleaning)  
[Add genres with the Spotify API](#add-genres-with-the-spotify-api)  
[Genres Analysis](#genres-analysis)  
[Skips Analysis](#skips-analysis)  
[Artists Analysis](#artists-analysis)  
[Albums Analysis](#albums-analysis)  
[Timestamps Analysis](#timestamps-analysis)  
[Release Date Analysis](#release-date-analysis)  
[Hours of the day Analysis](#hours-of-the-day-analysis)  



# How to get your spotify history files

You can get your own files from the Spotify [account privacy page](https://www.spotify.com/us/account/privacy/):  
- Scroll down to the end and check the box of the "Extended streaming history".  
- Click on the "Request data" button.  

It will take about a month for the data to be sent to you from Spotify.  



# Data Preparation and Cleaning

Load libraries and files, check for problematic data and give the data a more readable format.  
```
library(rjson)      # read the spotify streaming history files
library(ggplot2)    # make plots
library(tidyverse)  # useful functions
library(spotifyr)   # Spotify API functions
```
The first look at some key insights shows:  
- **4730**: total number of different songs played.  
- **21**: mean of the times a song was listened to.  
- **174**: total amount of days spent listening to music.  
- Top 20 most listened songs:  
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/songs_top20.png" width="800">  



# Add genres with the Spotify API

Spotify associates every song's genres with its artist's genres so all the songs of an artist will have the same genres.  
I'll use the Spotify API to get the genres of each artist.  
Check the [Spotify API documentation](https://developer.spotify.com/documentation/web-api) to understand how to get the 2 following IDs and then replacing the x with your own IDs:  
```
Sys.setenv(SPOTIFY_CLIENT_ID = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
Sys.setenv(SPOTIFY_CLIENT_SECRET = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
```
Note that there is a limit of about _5000_ operations a day, so it may take more than a single day to get all the needed data.  
After those operations this is how the songs dataframe looks:  
```
              artist                       song                song_id ms_played Freq              artist_id
1 Mone Kamishiraishi Nandemo Naiya - movie ver. 000A25aRKoyKyQywFHRXdI     14370    1 68TWc4rraWK3C522KFdt0b
2              Bcalm                  searching 006izA2xV3TS2IEIiFPQYM   2122777   19 7M4y7qvcYja7RcXNCGrjeP
3   Domenico Modugno     Nel blu dipinto di blu 006Ndmw2hHxvnLbJsBFnPx    216373    1 4llklDtTTyMYMY2LfFOkTI
4         Katy Perry            Unconditionally 009ImBOrIUlWgla8U05RAC    228878    1 6jJ0s89eD6GaHleKKya26X
5             Comodo                       Numb 00eIWlxr3jOX7nubbxHqJw   4055160   20 48Fimh8FHISFkwxpgOOvGe
6            Prozac+                      Acida 00NIByhDqGWbptOjm0dU4f    157466    1 74OFHbDbgVQi0IYb7gir5t
                                                                    genre
1                                                       j-acoustic, j-pop
2                                                focus beats, lo-fi study
3                                  classic italian pop, italian adult pop
4                                                                     pop
5                                                                chillhop
6 italian alternative, italian pop punk, italian punk, punk rock italiano
```

Genres appearing the most in the listened songs:
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/genres_raw_top20.png" width="800">  
This is how Spotify separates genres, some of the names look very similar without a clear difference on how they should sound differently.  
Which is why I'm going to group up the genres into macro categories, so instead of having, for example: italian pop, dance pop, k-pop, classic italian pop,... 
There is going to be the "pop" genre to group them all up.  

It is now possible to find out the most listened songs from a chosen list of genres (or without them)  
Top 20 most listened songs of the "dance","edm","electro","house" genres:
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/songs_+edm,.._top20.png" width="800">  
This plot only gets the songs that are part of at least one genre between "dance","edm","electro","house".  
The same plot can be made by only including or exluding any list of genres chosen.  



# Genres Analysis

It is now possible to make a more in-depth analysis of the differences between the genres.  
Top 10 most listened genres:  
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/ms_genres_top10.png">  

Violin x Scatter plot of the 10 most listened genres:  
(The biggest values aren't shown in the plot to see a clearer shape of the main distributions)  
(Only counting songs that have been played at least 30 times, to avoid the great amount of songs only played once or a few times)  
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/viol_genres_top20.png">  

The plots clearly show a much bigger number of pop songs compared to the other genres.  
Also, italian, dance and rap seem to have proportionally more songs with ~4-5 hours of playtime compared to the other genres,
which tend to have the majority of the songs played for ~2-3 hours, maybe hinting to a tendency of listening more at the most liked songs,
without spending much time exploring other songs not yet known.  

On the other hand, Japanese and korean seem to have proportionally the most songs with a low amount of playtime, ~2 hours, 
probably becuase these genres have been played only from the latest years, meaning various songs have been explored to determine if they are more or less enjoyable, 
which may have increased the number of songs which have been listened to fewer times.  

Another intereseting fact is lo-fi being seemigly split into 2 chunks, compared to the other genres it has the most songs with over 10 hours of playtime, 
but it also has a big block of songs played around the 2 hours mark.  
This might be a sign that the lo-fi songs are played mostly only in a few playlists dedicated to this genre only, 
which makes sense since lo-fi is mainly a relaxing kind of music and it might tend to be listened to mostly at particular times of the day or depending on the mood of the listener.  
By having less diversity in the tones and sounds compared to other genres it's less likely for lofi songs to be played uniformly among the day.  



# Skips Analysis

Another interesting analysis is done with the amount of times a song was skipped.  
But instead of using the skips values given in the Spotify data files (Not sure of the criteria that Spotify used).  
I'm going to consider a song skipped if it stopped playing before 30s, since the results reflect better the reality.  

The first insgiht to be seen is:  
- **17669** total skips, meaning about 18% of the songs listened were skipped.  

Distribution of the playing time of each song played:  
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/playing_time_distribution.png" width = "800">  
The orange line shows the 30s mark from which a song is considered skipped.  
As shown by the purple lines, the majority of the songs seem to be played between 100 and 275 seconds.  

From the amount of skips for each song, it's then possible to get respectively the 20 _least_ and _most_ skipped songs:  
(For a more interesting result, the plots show only the songs that have been played at least 125 times)  
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/skips_least_top20_F125.png" width = "415">
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/skips_most_top20_F125.png" width = "415">  

Since the least skipped songs plot is largely composed of lo-fi songs, by removing them there is most likely going to be an interesting difference:  
- Top 20 _least_ skipped not-lofi songs (which have been played at least 125 times)  
- Top 20 _most_ skipped rock songs (which have been played at least 25 times)

The resulting plots are:  
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/skips_least_-lofi_top20_F125.png" width = "410">
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/skips_most_+rock_top20_F25.png" width = "410">  



# Artists Analysis

Top 15 most listened artists with their most listened song:  
The smaller bars represent the percentage of the artist's most listened song over the total hours of playing time for the respective artist.  
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/artists_songs_top15.png">  
It's immediately clear that more than one artist is at the top thanks to only a single or few songs being listened to many times.  
Keeping this in mind, artists like Ed Sheeran and Bruno Mars, who have a relatively low percentage of the most played song over the total, suggests they are the actual most enjoyed artists, since they have many songs played consistently.  



# Albums Analysis

Top 15 most listened albums:  
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/albums_artists_top15.png" width = "800">  
Similarly with the artists top, more then one of the albums is at the top thanks to only one or a few songs listened.  
An interesting observation is the album GEMINI by Macklemore, being third even though neither the artist nor his songs are present in the most played respective tops, arguably making this album the most enjoyed as a hole.  



# Timestamps Analysis

This next part is designated to make use of the timestamps (yyyy-mm-dd/hh-mm-ss) of each song played, ranging from late 2017 to mid 2024.  

First look at the distribution of playing time across all the days:  
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/daily_distribution.png" width = "800">  
There is an apparent gap between early 2018 and the end of 2019, in which spotify wasn't used, there also seems to be an upward trend of playing time over the years.  

By working on the data, a few numbers come up:  
Every day about **2.74** hours are spent listening to music, which is about **83.2** hours a day.  
An interesting statistic derived from this:  
Considering the time spent sleeping every day is on average about 8h, it comes to about 122 days of the year spent sleeping.  
On the same logic, in this case, the time spent listening to music is about **42 days**.  

On top of that, the months and days with the most hours played are:
```
       MONTHS                              DAYS  
month year ms_played               timestamp ms_played
  Jun 2024    148.76               2023-06-04     14.23
  Jan 2023    148.68               2023-09-20     11.71
  Jan 2024    147.23               2024-06-21     11.39
  Jun 2022    135.72               2022-05-15     11.31
  May 2024    130.75               2024-06-19     11.18
  Dec 2021    126.34               2024-06-22     10.73
  Feb 2024    125.17               2022-06-25     10.57
  Apr 2022    120.64               2024-05-12     10.05
  Jan 2021    120.34               2023-07-11      9.96
  Mar 2024    119.75               2024-03-30      9.95
```  

Monthly distribution of playing time:  
The first plot shows all the years’ observations, ranging from 2017 to 2024  
The second one only shows the years which have songs played in every month of the year, thus keeping only the years between 2021 and 2023.  
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/monthly_distribution.png" width = "470">
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/monthly_distribution_cut_+mean.png" width = "470">  

There are some ideas of possible seasonality between the years:  
- A seemingly clear drop of playing time in august, probably since it's the usual time for a vacation and more outside activities by having more free time.  
- A spike of playing time between December and January, most likely due to speding more time at home becuase of the cold weather and the winter holidays.  

Though all in all the plot lines seeem to be quite variable, without clear seasonality among the years.  



# Release Date Analysis

Distribution of the time listened based on the release date of the songs:  
Each column represents the combined playing time of all the songs released in that year.  
The plots also show the comparison between 3 of the most played genres:   
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/release_ms_distribution.png" width = "470">
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/release_ms_distribution_+pop.png" width = "470">
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/release_ms_distribution_+rock.png" width = "470">
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/release_ms_distribution_+lofi.png" width = "470">  
From the first generic plot there is a clear spike of playing time in the year 2020, which might be explained by adding the lofi distribution in the last plot.
Since lofi is both a relatively new genre and one of the most played genres, it makes sense to have most of the songs come from the latest years.  
On the other hand, another both interesting and logical piece of information is that most of the older songs are rock, which doesn't surprise much thanks to its popularity at the time.  



# Hours of the day Analysis

Distribution of the hours spent listening to music among the different hours of the day:  
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/hourly_distribution_+rock.png" width = "470">
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/hourly_distribution_+lofi.png" width = "470">  
Both the rock and lo-fi distributions, as weel the other genres, don't seem to drift too much from the shape of the total distribution, apart from some slight changes.  

A clearer way to see the small differences can be done by utilizing the percentage of the genre columns over the total column height, with the blue line indicating the mean.  
The respective distribution of the percentage hours played of the specified genre over the total:  
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/hourly_distribution_perc_+rock.png" width = "470">
<img src="https://github.com/DakoDC/Analysis-of-My-Spotify-Data-in-R/blob/main/Images/hourly_distribution_perc_+lofi.png" width = "470">  
These last 2 plots show the hours of the day in which the specified genre is listened the most in percentage compared to the others.  
For example, even though the music played at 3am is much less then during the day, the rock genre is listened in proportion the most at those hours, making almost 30% of all the songs listened at 3am, compared to about 20% during the rest of the day.  
 
Interestingly at 4-5 am, the amount of lofi songs played compared to other genres is much higher then in the other hours of the day, almost reaching 50% of all the songs played at these hours.  
Also, lofi songs seem to be played more in the late or early times of the day, most likely due to the relaxing nature of the genre.  


