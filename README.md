# Playing-Attention
Code embodying the P(l)aying Attention application.  For general information and to cite, please see:

```
  @inproceedings{NIME20_33,
  author = {Gold, Nicolas E and Wang, Chongyang and Olugbade, Temitayo and Berthouze, Nadia and Williams, Amanda},
  title = {P(l)aying Attention: Multi-modal, multi-temporal music control},
  pages = {172--175},
  booktitle = {Proceedings of the International Conference on New Interfaces for Musical Expression},
  editor = {Michon, Romain and Schroeder, Franziska},
  year = {2020},
  month = jul,
  publisher = {Birmingham City University},
  address = {Birmingham, UK},
  issn = {2220-4806},
  doi = {10.5281/zenodo.4813303},
  url = {https://www.nime.org/proceedings/2020/nime2020_paper33.pdf}
}
```

## Requirements
This is a Processing sketch developed on Processing 3.5.4.  Download and install [Processing](https://processing.org/) (3.5.4 or later) and open the sketch.

Data dependencies are as follows.
### Sounds
Each music directory (`data/canon` and `data/perc` by default) should be populated with 13 files in .wav format and numbered 0.wav, 1.wav etc.

Each file should be of the same duration and will be mapped to a particular joint group as a channel.

### Data
This application sonifies relative attention paid to different joint groups.  Data should be ordered as frame-per-column at 60 frames per second.  The first 13 rows of each frame should contain a float representing the proportion of attention the particular joint group is receiving at that time (i.e. the 13 rows should sum to 1).  The 14th row should contain an integer 1 where protective behaviour has been detected and 0 otherwise.  For example:

```
0.1	0.05	...
0.05	0.1	...
0.05	0.05	...
0.05	0.05	...
0.1	0.1	...
0.1	0.1	...
0.1	0.25	...
0.1	0.0	...
0.1	0.1	...
0.1	0.05	...
0.05	0.05	...
0.05	0.05	...
0.05	0.05	...
1	0	...
```

Once the music files are in place, the sketch can be run.
