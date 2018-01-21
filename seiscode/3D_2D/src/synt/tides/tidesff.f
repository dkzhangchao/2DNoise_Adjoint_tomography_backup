c this is <tidesff.f>
c ----------------------------------------------------------------------------
c Copyright (c) 2002, 2015 by Thomas Forbriger (IMG Frankfurt) 
c
c This program computes synthetic tidal signals. It offers results
c caluclated by two different codes (see also below in the code):
c
c gez.f
c
c   Copyright (c) 1969 by R.A. Broucke, P. Muller (JPL)
c   Copyright (c) 1971 by R.A. Broucke, W. Zuern, L.B. Slichter
c   
c   Rigid earth gravity tides based on Brouckes code
c
c bfotide.f
c
c   Copyright (c) 1959 by Jon Berger, Russ Evans, and Dan McKenzie
c   Copyright (c) 1974 by Walter Zuern
c   Copyright (c) 1978 by David Young
c   
c   Earth response to tidal forces based on Longmans code
c
c Ephemerides used by gez.f are more accurate than those in bfotide.f
c gez.f provides rigid earth tidal acceleration, while bfotide.f
c provides the response of an elastic earth.
c
c ----
c This program is free software; you can redistribute it and/or modify
c it under the terms of the GNU General Public License as published by
c the Free Software Foundation; either version 2 of the License, or
c (at your option) any later version. 
c 
c This program is distributed in the hope that it will be useful,
c but WITHOUT ANY WARRANTY; without even the implied warranty of
c MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
c GNU General Public License for more details.
c 
c You should have received a copy of the GNU General Public License
c along with this program; if not, write to the Free Software
c Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
c ----
c
c REVISIONS and CHANGES
c    02/11/2002   V1.0   Thomas Forbriger
c    04/11/2002   V1.1   pass single variables to subroutines
c    31/07/2015   V1.2   provide output through libfapidxx
c
c ============================================================================
c
      program tidesff
c
      character*(*) version
      parameter(version='TIDESFF   V1.2   tides in SFF')
c 
c data
      character*80 outfile, outformat
      character*132 wid2line
      character*20 nsp
      parameter(nsp='NSP')
      integer ierr, lu
      parameter(lu=10)
      logical last
      integer msamp
      parameter(msamp=1000000)
      real fdata(msamp)
      integer idata(msamp)
      equivalence(fdata, idata)
c 
c times     
      integer startdate(7),sampint(7),enddate(7)
      integer tmpdate(7)
      integer argyear, argmonth, argday
c 
c general options
      integer argmode, argnsamp
      double precision arglat, arglon, argdt
      logical optoverwrite
      real samprat
c gez options
      integer argcmp
      double precision argfac, argheight
c bfotide options
c 
c gez specific
      integer doy
c
c commandline
      integer maxopt, lastarg, iargc
      character*80 argument
      parameter(maxopt=10)
      character*2 optid(maxopt)
      character*40 optarg(maxopt)
      logical optset(maxopt), opthasarg(maxopt)
c debugging
      logical debug, verbose
c here are the keys to our commandline options
      data optid/'-D', '-v', '-m', '-l', '-h', '-n', '-d', '-c', '-o',
     &           '-t'/
      data opthasarg/2*.FALSE.,6*.true.,.false.,.true./
      data optarg/2*'-','1','50.222,8.447','815.','1008','600.',
     &  '0,1.16','-','sff'/
c
c------------------------------------------------------------------------------
c basic information
c
c
      argument=' '
      if (iargc().eq.1) call getarg(1, argument)
      if ((argument(1:5).eq.'-help').or.(iargc().lt.4)) then
        print *,version
        print *,'Usage: tidesff year month day outfile'
        print *,'               [-v] [-d int] [-n n] [-l lat,lon]'
        print *,'               [-h h] [-m mode] [-c cmp,fac] [-o]'
        print *,'               [-t type]'
        print *,'   or: tidesff -help'
        if (argument(1:5).ne.'-help') 
     &    stop 'ERROR: wrong number of arguments'
        print *,' '
        print *,'Two programs are incorporated:'
        print *,'  GEZ.F copied from Gerhard Mueller'
        print *,'  BFOTIDE.F copied from Ruedi Widmer-Schnidrig'
        print *,' '
        print *,'Ephemerides used by gez.f are more accurate than those in bfotide.f'
        print *,'gez.f provides rigid earth tidal acceleration, while bfotide.f'
        print *,'provides the response of an elastic earth.'

        print *,' '
        print *,'You may select using the mode-parameter'
        print *,' '
        print *,'year         year of first sample'
        print *,'month        month of first sample'
        print *,'day          day of first sample'
        print *,'             first sample will always be at 0:00UT'
        print *,'             on the specified day'
        print *,'outfile      output data file'
        print *,' '
        print *,'general options'
        print *,'---------------'
        print *,' '
        print *,'-v           be verbose'
        print *,'-o           overwrite existing output'
        print *,' '
        print *,'-m mode      mode=1 use GEZ code'
        print *,'             mode=2 use BFOTIDE code'
        print *,'             (default=',optarg(3)(1:1),')'
        print *,'-l lat,lon   latitude and longitude of station'
        print *,'             location. North and east are positive.'
        print *,'             (default=',optarg(4)(1:12),')'
        print *,'-n n         number of samples to be calculated'
        print *,'             (default=',optarg(6)(1:4),')'
        print *,'-d int       sampling interval in seconds'
        print *,'             (default=',optarg(7)(1:4),')'
        print *,'-t type      select output file type'
        print *,'             (default=',optarg(10)(1:3),')'
        print *,'             for more type options see below'
        print *,' '
        print *,'GEZ options'
        print *,'-----------'
        print *,' '
        print *,'GEZ calculates tides for a rigid earth. To obtain'
        print *,'true tidal accelerations, you have to specify a'
        print *,'correction factor. Units are mGal.'
        print *,' '
        print *,'-h h         station height in metres'
        print *,'             (default=',optarg(5)(1:4),')'
        print *,'-c cmp,fac   component and correction factor.'
        print *,'             cmp=0 vertical'
        print *,'             cmp=1 north'
        print *,'             cmp=2 east'
        print *,'             (default=',optarg(8)(1:6),')'
        print *,'             Kertz suggests fac=1.2 for Z and'
        print *,'             fac=0.72 for N'
        print *,' '
        print *,'BFOTIDE options'
        print *,'---------------'
        print *,' '
        print *,'Kleiner Tip:'
        print *,'Dieses Programm enthaelt die Zeitgleichung'
        print *,'(subroutine sun).'
        print *,' '
        print *,'Copyright notice for gez.f'
        print *,'--------------------------'
        call gez_copyright
        print *,' '
        print *,'Copyright notice for bfotide.f'
        print *,'------------------------------'
        call bfotide_copyright
        print *,' '
        call sff_help_formats
        stop
      endif
c
c------------------------------------------------------------------------------
c read command line arguments
c
      call tf_cmdline(4, lastarg, maxopt, optid,
     &                optarg, optset, opthasarg)
      debug=optset(1)
      verbose=optset(2)
      read(optarg(3), *, err=99, end=98) argmode
      read(optarg(4), *, err=99, end=98) arglat,arglon
      if (abs(arglon).gt.180.) stop 'ERROR: longitute range'
      if (abs(arglat).gt.180.) stop 'ERROR: latitude range'
      read(optarg(5), *, err=99, end=98) argheight
      read(optarg(6), *, err=99, end=98) argnsamp
      if (argnsamp.lt.2) stop 'ERROR: less than two samples'
      if (argnsamp.gt.msamp) stop 'ERROR: too many samples'
      read(optarg(7), *, err=99, end=98) argdt
      if (argdt.lt.0.) stop 'ERROR: negative sampling interval'
c      print *,'argdt: ',argdt
      read(optarg(8), *, err=99, end=98) argcmp,argfac
      optoverwrite=optset(9)
      outformat=optarg(10)
c 
      call getarg(1, argument)
      read(argument, *, err=99, end=98) argyear
      call getarg(2, argument)
      read(argument, *, err=99, end=98) argmonth
      call getarg(3, argument)
      read(argument, *, err=99, end=98) argday
      call getarg(4, outfile)
c
c------------------------------------------------------------------------------
c go
c 
c assemble time of first sample
      call time_clear(startdate)
      call time_clear(sampint)
      call time_clear(enddate)
      startdate(1)=argyear
      call time_setdoy(argday, argmonth, startdate)
      call sffu_dttotime(sngl(argdt), sampint)
      call time_mul(sampint, tmpdate, (argnsamp-1))
      call time_add(startdate,tmpdate,enddate)
      if (verbose) then
        print *,version
        print *,' '
        call time_sprint(startdate, argument)
        print *,'calculate tides starting with'
        print *,'  ',argument(1:35)
        call time_sprint(sampint, argument)
        print *,'sampling interval is'
        print *,'  ',argument(1:35)
        print *,'we will calculate ',argnsamp,' samples'
        call time_sprint(enddate, argument)
        print *,'last sample will be at'
        print *,'  ',argument(1:35)
      endif
      argyear=startdate(1)
      call time_getdate(argday, argmonth, startdate)
c 
c tell station location
      if (verbose) then
        print *,'specified station location:'
        if (arglat.gt.0.) then
          print 50,arglat,'N'
        else
          print 50,-arglat,'S'
        endif
        if (arglon.gt.0.) then
          print 50,arglon,'E'
        else
          print 50,-arglon,'W'
        endif
      endif
c
c----------------------------------------------------------------------
c open output file
      if (verbose) print *,' '
      if (optoverwrite) then
        if (verbose) then
          print *,'remove ',outfile(1:index(outfile,' ')-1)
        endif
        call sff_New(lu, outfile, ierr)
        if (ierr.ne.0) stop 'ERROR: deleting file'
      endif
      if (verbose) then
        print *,'open ',outfile(1:index(outfile,' ')-1)
      endif
      call sff_select_output_format(outformat, ierr)
      if (ierr.ne.0) stop 'ERROR: selected file format is not supported'
      call sff_WOpen(lu, outfile, ierr)
      if (ierr.ne.0) stop 'ERROR: opening file'
      last=.false.
c 
      samprat=sngl(1./argdt)
      call sff_PrepWID2(argnsamp, samprat, nsp,
     &  argyear, argmonth, argday, 0, 0, nsp, nsp, nsp, 0.,
     &  -1., -1. ,-1. ,-1., wid2line, ierr) 
      if (ierr.ne.0) stop 'ERROR: creating WID2 line'
c
c switch
      if (argmode.eq.1) then
        if (verbose) then
          print *,' '
          print *,'using GEZ'
          print *,'---------'
          print *,' '
          print *,'station height (m): ',argheight
          if (argcmp.eq.0) then
            print *,'vertical component'
          elseif (argcmp.eq.1) then
            print *,'north component'
          elseif (argcmp.eq.2) then
            print *,'east component'
          else
            stop 'ERROR: invalid component index'
          endif
          print *,'correction factor: ',argfac
        endif
        if (argcmp.eq.0) then
          wid2line(36:38)='Z  '
        elseif (argcmp.eq.1) then
          wid2line(36:38)='N  '
        elseif (argcmp.eq.2) then
          wid2line(36:38)='E  '
        endif
        doy=startdate(2)
c definition of longitude is to west
        arglon=-arglon
c definition of component 1 is south, not north
        if (argcmp.eq.1) argfac=-argfac
        call geztides(fdata, msamp, argnsamp, argdt, 
     &    argyear, doy, arglat, arglon, argheight,
     &    argcmp, argfac)
        last=.true.
        call sff_WTrace(lu, wid2line, argnsamp, fdata, idata, 
     &    last, ierr)
        if (ierr.ne.0) stop 'ERROR: writing SFF trace'
      elseif (argmode.eq.2) then
        if (verbose) then
          print *,' '
          print *,'using BFOTIDE'
          print *,'-------------'
        endif
        stop 'ERROR: BFOTIDE not yet implemented'
      else
        print *,'selected mode: ',argmode
        STOP 'ERROR: unknown mode'
      endif
      call sff_close(lu, ierr)
      if (ierr.ne.0) stop 'ERROR: closing output file'
c
      stop
   50 format(3x,f10.4,1h�,a1)
   99 stop 'ERROR: option argument'
   98 stop 'ERROR: too few arguments'
      end
c======================================================================
c source code of GEZ.F
c
c Copyright (c) 1969 by R.A. Broucke, P. Muller (JPL)
c Copyright (c) 1971 by R.A. Broucke, W. Zuern, L.B. Slichter
c
c Rigid earth gravity tides based on Brouckes code
c
c This program calculates tidal acceleration as would be observed on a
c spherically symmetric rigid earth. The calculation is based on
c ephemerides calculated in subroutines from JPL (Roger Broucke). The
c Moon's ephemeris is based on Brown's theory, the Sun's ephemeris is
c based on Newcomb's theory.
c
c See: 
c R.A. Broucke, W.E. Zuern, L.B. Slichter, 1972. Lunar Tidal
c Acceleration on a Ridig Earth. Geophysical Monograph Series, Vol. 16.
c 319 - 324. American Geophysical Union, Washington, D.C.
c
c ----
c This program is free software; you can redistribute it and/or modify
c it under the terms of the GNU General Public License as published by
c the Free Software Foundation; either version 2 of the License, or
c (at your option) any later version. 
c 
c This program is distributed in the hope that it will be useful,
c but WITHOUT ANY WARRANTY; without even the implied warranty of
c MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
c GNU General Public License for more details.
c 
c You should have received a copy of the GNU General Public License
c along with this program; if not, write to the Free Software
c Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
c ----
c 
c Modified Version
c writes also table output file
c
C***********************************************************************
C     TIDAL ACCELERATION OF RIGID EARTH
C            VERSION FOR EQUIDISTANT TIME SERIES WITH ARBITRARY START TI
C***********************************************************************
C     INPUT(FILE#5) :
C 1)  OL, OM       (2F8.3)    STATION LONGITUDE IN DEG., MIN (EAST -)
C 2)  AL, AM       (2F8.3)    STATION LATITUDE  IN DEG., MIN (SOUTH -)
C 3)  HT           (F8.3)     STATION HEIGHT    IN METERS
C     DELH,DELM    (2F8.3)    TIMESTEP(HOURS,MINUTES RESPECTIVELY)
C 4)  ATAG,AJAHR (2I5)        START: DAY OF YEAR,YEAR
C 5)  STHR,STMN,KLOOP (2F8.3,4X,I10)
C                             START: HOUR,MINUTE/TOTAL NUMBER OF POINTS
C 6)  S1, KORR     (2X,I2,2X,F10.5) S1 = KOMPONENT : 0 - VERTICAL
C                                                  1 - HORIZ.(SOUTH)
C                                                2 - HORIZ.(EAST)
C                                KORR = ARBITRARY FACTOR
C
C***********************************************************************
      subroutine geztides(fdata, msamp, argnsamp, argdt, 
     &    argyear, argdoy, arglat, arglon, argheight,
     &    argcmp, argfac)
c 
      integer msamp
      real fdata(msamp)
      integer argnsamp, argyear, argdoy, argcmp
      double precision argdt, arglat, arglon, argheight, argfac
c 
      DIMENSION G(1000000),IIG(1000000),MH(12)
      INTEGER ATAG,AJAHR,S1
      DOUBLE PRECISION HTD,ALD,AMD,OLD,OMD,yrsd,hrsdd,daysrd,gs,gm,
     1 daysd,t,tujd,tejd,hem,hsm,hes,hss,dstep,si
      REAL KORR
C***** INPUT + FEEDBACK ***********************************************
c      OPEN(UNIT=5,FILE='GEZDAT.')
C     OPEN(UNIT=8,FILE='SYSOUT')
c      OPEN(UNIT=8,FILE='GEZERG.')
c      READ(5,101)OL,OM
c      READ(5,101)AL,AM
c  101 FORMAT(2F8.3)
c      READ(5,102) HT,DELH,DELM
c  102 FORMAT(3F8.3)
c      READ(5,103) ATAG,AJAHR
c      READ(5,131) STHR,STMN,KLOOP
c  131 FORMAT(2f8.3,4x,i10)
c  103 FORMAT(2I5)
c      READ(5,104) S1,KORR
c  104 FORMAT(2X,I2,2X,F10.5)
c      IF(S1.EQ.0) WRITE(8,105)
c      IF(S1.EQ.1) WRITE(8,106)
c      IF(S1.EQ.2) WRITE(8,107)
c  105 FORMAT(2X,'COMPUTATION OF VERTICAL TIDAL ACCELERATION')
c  106 FORMAT(2X,'COMPUTATION OF HORIZONTAL(SOUTH) TIDAL ACCELERATION')
c  107 FORMAT(2X,'COMPUTATION OF HORIZONTAL(EAST) TIDAL ACCELERATION')
c      WRITE(8,108)OL,OM
c  108 FORMAT(2X,'STATION LONGITUDE',2X,F5.0,'DEG',F5.0,1H')
c      WRITE(8,109)AL,AM
c  109 FORMAT(2X,'STATION LATITUDE',3X,F5.0,'DEG',F5.0,1H')
c      WRITE(8,110) HT,DELH,DELM
c  110 FORMAT(2X,'STATION HIGHT',5X,F8.3,'M',5X,'TIMESTEP ',F8.3,'H',
c     1F8.3,'MIN')
c      WRITE(8,111) ATAG,AJAHR
c  111 FORMAT(2X,'START  DAY : ',I5,'  OF YEAR:',I5)
c      WRITE(8,132) STHR,STMN
c  132 FORMAT(2x,' HOURS:',f8.3,'   MINUTES:  ',f8.3)
c 
      S1=argcmp
      KORR=sngl(argfac)
      AJAHR=argyear
      ATAG=argdoy
      STHR=0.
      STMN=0.
      KLOOP=argnsamp
      HT=sngl(argheight)
c 
      al=float(int(arglat))
      am=(arglat-al)*60.
      ol=float(int(arglon))
      om=(arglon-ol)*60.
c      print *,'lat ',al,am
c      print *,'lon ',ol,om
c 
      DELH=float(int(argdt/3600.))
      DELM=(argdt/60.)-(DELH*60.)
c      print *,'sampling ',delh,'h ',delm,'min'
c 
      htd=dble(ht)
      ald=dble(al)
      amd=dble(am)
      old=dble(ol)
      omd=dble(om)
C***********************************************************************
      CALL RIGTID(HTD,ALD,AMD,OLD,OMD)
C***********************************************************************
      YRS= FLOAT(AJAHR-1900)
   51 DAYSR= FLOAT(ATAG)
C**********************************************************************
      K=1
      DSTEP=DELH+DELM/60.d0
      SI=-DSTEP+sthr+stmn/60.d0
   56 IF(K.GT.KLOOP) GOTO 59
   58 SI=SI+DSTEP
      HRSD=SI
      yrsd=dble(yrs)
      daysrd=dble(daysr)
      hrsdd=dble(hrsd)
      hrsdd=SI
      CALL RIGTIM(YRSD,DAYSRD,HRSDD,GS,GM,DAYSD,T,TUJD,TEJD,HEM,HSM,
     1HES,HSS)
      gss=sngl(gs)
      gms=sngl(gm)
      hems=sngl(hem)
      hsms=sngl(hsm)
      hess=sngl(hes)
      hsss=sngl(hss)
      IF(S1.EQ.0) G(K)=(GSS +GMS )*KORR
      IF(S1.EQ.1) G(K)=(HSSS+HSMS)*KORR
      IF(S1.EQ.2) G(K)=(HESS+HEMS)*KORR
      K=K+1
      if(HRSD.LT.24.00)  GOTO 56
      SI=SI-24.d0
      DAYSR=DAYSR+1.000
      GOTO 56
   59 CONTINUE
C***** OUTPUT ******************************************************
      DO 300 K=1,KLOOP,1
      IIG(K)=G(K)*10.
  300 CONTINUE
c      WRITE(8,124)KLOOP
c  124 FORMAT(2X,'NUMBER OF VALUES   :',I5)
c      WRITE(8,122)KORR
c  122 FORMAT(2X,'ALL VALUES IN  (MYCGAL*E-1)  * ',F10.5)
c      DO 200 K=1,KLOOP,12
c      WRITE(8,121)(IIG(J),J=K,K+11,1)
c  121 FORMAT(20X,12I5)
c  200 CONTINUE
c      call varplt(G,kloop,0,1,0.,0.,0.,0.)
c 
c write to table
c      print *,'output to ''gez.dat'' with the following units:'
c      print *,'  time: seconds since beginning of year'
c      print *,'  gravity: mGal'
c      open(12, file='gez.dat')
c      do k=1,kloop
c        write(12, 201) 
c     &    (((atag-1)*24.d0+sthr)*60.d0+stmn)*60.d0+
c     &    ((delh*60.d0+delm)*60.d0)*(k-1), g(k)*1.e-3
c  201 format(2(2x,g20.14))
c      enddo
c      close(12)
      do k=1,kloop
        fdata(k)=g(k)*1.e-3
      enddo
c
      return
      END
c
c----------------------------------------------------------------------
c 
      SUBROUTINE RIGTID(HT,AL,AM,OL,OM)
C  THIS SUBROUTINE AND THE ONES CALLED COMPUTE VERTICAL (POSITIVE UPWARD
C  HORIZONTAL TIDAL ACCELERATIONS DUE TO SUN AND MOON.THE BASIC FEATURES
C   THE PROGRAM AND ITS ACCURACY ARE DISCUSSED IN
C      BROUCKE,R.A.;ZURN,W;SLICHTER,L.B.
C      LUNAR TIDAL ACCELERATION ON A RIGID EARTH
C      GEOPHYSICAL MONOGRAPH 16,FLOW AND FRACTURE OF ROCKS
C      (THE GRIGGS VOLUME),A.G.U.,WASH.,1972,319-324
      IMPLICIT REAL*8(A-H,O-Z)
      DOUBLE PRECISION XELSUN(21),XCSUN(5)
c 
c Thomas Forbriger 24/05/2002:
c This subroutine calculates some constants, that will be used later by the
c entry-point RIGTIM. In the old version these variables were not declared to
c be static. 
c 
      save ds0,gm0,gm1,gs0,alm,gl,cosal,sinal,r,olm,omm      
c
C
C  INPUT PARAMETERS
C
C     HT   STATION HEIGHT ABOVE SEA LEVEL IN METERS
C     OL   DEGREES OF STATION LONGITUDE , WEST + ,EAST -
C     OM   MINUTES OF STATION LONGITUDE
C     AL   DEGREES OF STATION LATITUDE, SOUTH -
C     AL   MINUTES OF STATION LATITUDE
      REAL*8 CNZERO  /0.0D0/
      REAL*8 CNHALF /0.5D0/
      REAL*8 CN1 /1.0D0/
      REAL*8 CN2 /2.0D0/
      REAL*8 CN3  /3.0D0/
      REAL*8 CN4 /4.0D0/
      REAL*8 CN5  /5.0D0/
      REAL*8 CN12 / 12.0D0/
      REAL*8 CN15 /15.0D0/
      REAL*8 CN24 /24.0D0/
      REAL*8 CN35  /35.0D0/
      REAL*8 CN60 /60.0D0/
      REAL*8 CN100  /100.0D0/
      REAL*8 CN360 /360.0D0/
      REAL*8 CN365 /365.0D0/
      REAL*8 C36525  /36525.0D0/
      REAL*8 W  /23.4519591D0/
C     SCALED 10**(-3)
      REAL*8 RADIUS  /6.37816D0/
C     SCALED 10**(-3)
      REAL*8 CVTKM   /.000001D0/
C     SCALED 10**(-8)
      REAL*8 ESDIST /1.495985D0/
      REAL*8 ASTRUN/1.49597870D0/
C     SCALED   10**(-19)
      REAL*8 GTME   /39.8603D0/
C     SCALED   10**(-2)
      REAL*8  RMEM   / 0.8130D0/
C     SCALED   10**(-6)
      REAL*8  RMSE   /0.332958D0/
      REAL*8 SCLGM1 /10000000.0D0/
      REAL*8 R1 /.00673966D0/
C
      REAL*8 DEGRAD /  .017453292519943D0/
      REAL*8 EPOCH /2415020.0D0/
      REAL*8 TWOPI /  6.283185307179586D0/
      REAL*8 RNDOFF /.00001D0/
C
      REAL*8 H0  /279.69668D0/
      REAL*8 H1  /36000.76892D0/
      REAL*8 H2  /0.0003D0/
C
      REAL*8 ES0  /0.01675104D0/
      REAL*8 ES1  /0.0000418D0/
      REAL*8 ES2  /0.000000126D0/
C
      REAL*8 PS0  /281.22083D0/
      REAL*8 PS1  /1.71902D0/
      REAL*8 PS2  /0.00045D0/
      REAL*8 PS3  /0.000003D0/
C
C  COMPUTE PROGRAM CONSTANTS
C
      SINW = DSIN(W*DEGRAD)
      COSW = DCOS(W*DEGRAD)
C
      CF1 = (CN1 + COSW)*CNHALF
      CF2 = (CN1 - COSW)*CNHALF
C
      ESDIST=ASTRUN
      DS0 = CN1/ESDIST
C
      GM0=GTME*SCLGM1/RMEM
      GM1=CN3*GTME*SCLGM1/(RMEM*CN2)
C
      GS0=GTME*RMSE
C
      R0 = CN1 + R1
C
      HT=HT*CVTKM
      ALM=(AL+AM/CN60)*DEGRAD
C    COMPUTE GEOCENTRIC LATITUDE
      GL=ALM
      POLES=CN4*DABS(ALM)
      IF(POLES.EQ.TWOPI)    GO TO 3
      ALM=DATAN(DSIN(ALM)/DCOS(ALM)/R0)
 3    CONTINUE
      COSAL = DCOS(ALM)
      SINAL = DSIN(ALM)
      R = HT + RADIUS/DSQRT(R0 - R1*COSAL**2)
      OLM=OL
      OMM=OM
      RETURN
      ENTRY RIGTIM(YRS,DAYSR,HRSD,GS,GM,DAYSD,T,TUJD,TEJD,HEM,HSM,HES,HS
     1S)
C
C  INPUT PARAMETERS
C
C     YRS  LAST TWO DIGITS OF YEAR IN 20TH CENTURY
C     DAYSR    DAY OF THE YEAR
C     HRSD    HOURS AND FRACTION OD HOURS IN GREENWICH MEAN TIME
C   OUTPUT PARAMETERS
C     GS   TIDAL ACCELERATION BY THE SUN
C     GM   TIDAL ACCELERATION BY THE MOON
C   T IS THE NUMBER OF JULIAN CENTURIES SINCE DEC.31,1899
C    DAYSD IS THE NUMBER OF DAYS PAST SINCE NOON DEC. 31,1899 ,
C   THE IDINT EXPRESSION IS THE NUMBER OF LEAP YEARS PAST(NOTE THAT
C  ALL YEARS DIVISIBLE BY 4 EXCEPT 1900 ARE LEAP YEARS )
C     TUJD JULIAN DATE IN DAYS AND FRACTIONS OF DAYS (UNIVERSAL TIME)
C     TEJD JULIAN DATE IN DAYS AND FRACTIONS OF DAYS ( EPHEMERIS TIME)
C   HRSD IS GREENWICH MEAN TIME
C     TJY  JULIAN DATE IN YEARS AND FRACTION OF YEARS (UNIVERSAL)
C      HORIZONTAL TIDAL ACCELERATIONS IN MICROGAL
C
C        HSM - MOON,SOUTH
C        HEM - MOON,EAST
C        HSS - SUN,SOUTH
C        HES - SUN,EAST
C
C
C
C
      DAYSD = YRS*CN365 + DAYSR - CNHALF + IDINT((YRS - CN1)/CN4
     1  + RNDOFF) + HRSD/CN24
C
      T = DAYSD/C36525
C
      TUJD=DAYSD+EPOCH
      TJY=DAYSD/C36525*CN100
C
      CALL ETMUTC(TJY,ETUT)
      TEJD=TUJD+ETUT/CN24/CN60/CN60
C
      CALL GSTIME(TUJD,AGST)
      AGST=(AGST-CN12)*CN15*DEGRAD
C
C
C    POSITION AND VERTICAL TIDAL ACCELERATION,SUN
      CALL SUN(TEJD,XELSUN,XCSUN)
      W=XELSUN(3)
      XCSUN(4)=XCSUN(4)-20.47D0/CN60/CN60/XCSUN(1)*DEGRAD
      DS=DS0/XCSUN(1)
      CALL NUTAN(TEJD,ANUTL,ANUTO)
      DSOLS=DSIN(XCSUN(4)+ANUTL)
      DSOLC=DCOS(XCSUN(4)+ANUTL)
      DSALS=DSIN(XCSUN(5))
      DSALC=DCOS(XCSUN(5))
      OBLIQ=W*DEGRAD+ANUTO
      SINOB=DSIN(OBLIQ)
      COSOB=DCOS(OBLIQ)
      SINDS=SINOB*DSOLS*DSALC+COSOB*DSALS
      COSDS=DSQRT(CN1-SINDS*SINDS)
      COSHS=DSOLC*DSALC/COSDS
      SINHS=(COSOB*DSOLS*DSALC-SINOB*DSALS)/COSDS
      HA=AGST-(OLM+OMM/CN60)*DEGRAD
      COSHA=DCOS(HA)
      SINHA=DSIN(HA)
      TAUCOS=COSHA*COSHS+SINHA*SINHS
      TAUSIN=SINHA*COSHS-COSHA*SINHS
      CF=SINAL*SINDS+COSAL*COSDS*TAUCOS
C
C
      GSK0=GS0*R*DS**3
      GS=GSK0*(CN3*CF**2-CN1)
C
C    POSITION AND VERTICAL TIDAL AVCELERATION,MO6N
C
      CALL CRMOON(TEJD,DEKLIN,RIGAS,PAR)
      DA=DSIN(PAR)/RADIUS
      TAU =AGST-RIGAS-(OLM+OMM/CN60)*DEGRAD
      TAU=DMOD(TAU,TWOPI)
      COSTAU=DCOS(TAU)
      SINTAU=DSIN(TAU)
      SINDEK=DSIN(DEKLIN)
      COSDEK=DCOS(DEKLIN)
      CT=SINAL*SINDEK+COSAL*COSDEK*COSTAU
C
      GMK0=GM0*R*DA**3
      GMK1=GM1*(R**2)*(DA**4)
      GMK2=GM0*(R**3)*(DA**5)
C
      GM=GMK0*(CN3*CT**2-CN1)+GMK1*(CN5*CT**3-CN3*CT)
      GM=GM+GMK2*(CN3/CN2+CN35/CN2*CT**4-CN15*CT**2)
C
C  HORIZONTAL ACCELERATIONS DUE TO THE SUN
C
      HAID=GSK0*CN3*CF
      HES= -HAID*COSDS*TAUSIN
      HSS=HAID*(COSAL*SINDS-SINAL*COSDS*TAUCOS)
      HSS=-HSS
C
C     HORIZONTAL ACCELERATIONS DUE TO THE MOON
      HAID=GMK0*CN3*CT+GMK1*(CN5*CT**2-CN1)
      HAID=HAID+GMK2*(CN35/CN2*CT**3-CN15/CN2*CT)
      HEM=-HAID*COSDEK*SINTAU
      HSM=HAID*(COSAL*SINDEK-COSTAU*COSDEK*SINAL)
      HSM=-HSM
C    TRANSFORM TO THE NORMAL ON THE SPHEROID
      COSPSI=COS(GL-ALM)
      SINPSI=SIN(GL-ALM)
      GSC=GS*COSPSI-HSS*SINPSI
      HSS=HSS*COSPSI+GS*SINPSI
      GS=GSC
      GMC=GM*COSPSI-HSM*SINPSI
      HSM=HSM*COSPSI+GM*SINPSI
      GM=GMC
      RETURN
      END
c
c----------------------------------------------------------------------
c
      SUBROUTINE SUN(DJ,EL,C)
C     SUN EARTH EPHEMERIS  R. BROUCKE CONVERTED TO 360
C     P. MULLER JPL  DEC 69
C
C     ROGER BROUCKE,  JET PROPULSION LABORATORY
C
C     NEWCOMB EARTH EPHEMERIS, ASTRONOMICAL PAPERS, VOLUME 6, PART 1.
C     THE FUNDAMENTAL EPOCH IS 1900,JAN 0,GREENWICH MEAN NOON=2415020.0
C     THE TIME IS IN JULIAN DAYS (36525 DAYS PER JULIAN CENTURY)
C     EL(1)=MEAN SEMI-MAJOR-AXIS OF THE EARTH, IN ASTRONOMICAL UNITS
C     EL(2)=ECCENTRICITY OF THE EARTH'S ORBIT
C     EL(3)=MEAN OBLIQUITY OF THE EARTH, IN DEGREES
C     EL(4) AND EL(6) ARE NOT USED, (=ALWAYS ZERO)
C     EL(5)=LONGITUDE OF PERIGEE OF THE SUN, FREE FROM ABERRATION
C     EL(7)=TIME IN JULIAN DAYS
C     EL(8)=MEAN SIDEREAL MOTION OF THE SUN IN DEGREES PER JULIAN DAY
C     EL(9)=MEAN GEOMETRIC LONGITUDE OF THE SUN, FREE FROM ABERRATION
C     EL(10)=MEAN ANOMALY OF THE EARTH, IN DEGREES
C     EL(11)=MEAN RADIUS VECTOR OF THE EARTH, IN ASTRONOMICAL UNITS
C     EL(12)=EQUATION OF THE CENTER OF THE EARTH, IN DEGREES
C        = (TRUE-MEAN) ANOMALY
C     EL(13)=RIGHT ASCENSION OF FICTITIOUS MEAN SUN, FREE FROM
C        ABERRATION, IN HOURS =
C        =MEAN LONGITUDE OF FICTITIOUS MEAN SUN
C        =GREENWICH SIDEREAL TIME OF MEAN NOON, UNCORRECTED FOR NUTATION
C        =SIDEREAL TIME MINUS MEAN GREENWICH TIME(UNCORRECTED FOR NUTAT)
C     SIDEREAL TIME=MEAN R.A.M.S. +NUTATION IN R.A.
C     THE NUTATION IN R.A. IS(NUT.IN LONGITUDE)*COSINE(TRUE OBLIQUITY),
C        DIVIDED BY 15 TO REDUCE TO SECONDS OF TIME
C     EL(14)=MEAN LONGITUDE OF THE MOON, IN DEGREES
C     EL(15)=MEAN ANOMALY OF THE MOON, IN DEGREES
C        EL(15)=EL(14)-EL(21)
C     EL(16)=MEAN ARGUMENT OF LATITUDE OF THE MOON, IN DEGREES
C     EL(17)=MEAN LONGITUDE OF THE ASCENDING NODE OF THE MOON
C     EL(18)=PRECESSIONAL CONSTANT IN DEGREES PER JULIAN CENTURY
C     EL(19)=NUTATION IN LONGITUDE IN DEGREES
C     EL(20)=NUTATION IN OBLIQUITY IN DEGREES
C     EL(21)=MEAN LONGITUDE OF PERIGEE OF THE MOON IN DEGREES
C     C(1)=TRUE RADIUS VECTOR OF THE SUN, IN ASTRONOMICAL UNITS
C     C(2)=SUN'S TRUE GEOMETRIC LONGITUDE,W.R.TO MEAN EQUINOX OF DATE
C     C(2) IS IN DEGREES AND C(4)=C(2), BUT IN RADIANS
C     TO HAVE THE APPARENT LONGITUDE OF THE SUN, THE ABERRATION MUST
C     BE SUBTRACTED
C     TO HAVE THE LONGITUDE W.R.TO THE TRUE EQUINOX, ADD NUTAT IN LONG.
C     C(3)=SUN'S TRUE GEOMETRIC LATITUDE
C     C(3) IS IN DEGREES AND C(5)=C(3), BUT IN RADIANS
C     REMARK. THE NUTATION HAS NO EFFECT ON THE LATITUDE.
      DOUBLE PRECISION DJ,EL,C,T,TP,GME,GVE,GJU,GMA,GSA,GPL,T2,T3
     1,DV,DR,DB,R0,RJ,RI,DEGRAD,RADDEG,TWOPI, GRAD, AUP, AD
     2,E,SMALOG
      DOUBLE PRECISION REGRAD
      REAL SL,SR,SLA,AL,AR,ALA,ARV,ARR,ARG
      INTEGER JLR,ILR,JLA,ILA
      DIMENSION EL(21),C(5),JLR(120),ILR(120),JLA(34),ILA(34),E(11),
     1SL(120),SR(120),SLA(34),AL(120),AR(120),ALA(34)
      DATA DEGRAD,RADDEG,TWOPI
     1/.017453292519943296D0,57.295779513082321D0,6.2831853071795864D0/
C     THE COEFFICIENTS OF FOURIER SERIES ARE IN THE 10 FOLLOWING TABLES
C     JLR=INDEX J FOR LONGITUDE AND RADIUS
      DATA  JLR   /-1,-1,-1,-1,-1,-1,-1,-1,-2,-2,-2,-2,-2,
     1-3,-3,-3,-3,-3,-4,-4,-4,-4,-4,-5,-5,-5,-5,-6,-6,-6,-6,-7,-7,-7,-7,
     2-8,-8,-8,-8,-8,-9,-9,-10,+1,+1,+1,+2,+2,+2,+2,+3,+3,+3,+3,
     3+4,+4,+4,+4,+5,+5,+5,+5,+6,+6,+6,+6,+7,+7,+7,+8,+8,+8,+8,+9,+9,+9,
     4+10,+10,+10,+11,+11,+12,+13,+13,+15,+15,+17,+17,+1,+1,+1,+1,+1,
     5+2,+2,+2,+2,+3,+3,+3,+3,+4,+4,+4,+4,+5,+5,+5,+5,+1,+1,+1,+1,
     6+2,+2,+2,+2,+3,+3,+4/
C     ILR=INDEX I FOR LONGITUDE AND RADIUS
      DATA  ILR    /+1,+2,+3,+4,+0,+1,+2,+3,+0,+1,+2,+3,+4,
     1+2,+3,+4,+5,+6,+3,+4,+5,+6,+7,+5,+6,+7,+8,+6,+7,+8,+9,+7,+8,+9,+10
     2,+8,+9,+12,+13,+14,+9,+10,+10,-2,-1,+0,-3,-2,-1,+0,-4,-3,-2,-1,
     3-4,-3,-2,-1,-5,-4,-3,-2,-6,-5,-4,-3,-6,-5,-4,-7,-6,-5,-4,
     4-7,-6,-5,-7,-6,-5,-7,-6,-7,-8,-7,-9,-8,-10,-9,-3,-2,-1,+0,+1,
     5-3,-2,-1,+0,-4,-3,-2,-1,-4,-3,-2,-1,-5,-4,-3,-2,-2,-1,+0,+1,
     6-3,-2,-1,+0,-2,-1,-2/
C     JLA=INDEX J FOR LATITUDE
      DATA  JLA    /-1,-1,-1,-1,-2,-2,-2,-2,-3,-3,-3,-3,-3,
     1-4,-4,-4,-5,-5,-6,-6,-6,-8,+2,+2,+4,+1,+1,+1,+1,+2,+3,+3,+1,+1/
C     ILA=INDEX I FOR LATITUDE
      DATA  ILA     /+0,+1,+2,+3,+1,+2,+3,+4,+2,+3,+4,+5,+6,
     1+3,+5,+6,+6,+7,+5,+7,+8,+12,-2,+0,-3,-2,-1,+0,+1,-1,-2,-1,-1,+1/
C     SL = COEFFICIENTS S FOR LONGITUDE
      DATA  SL   /.013,.005,.015,.023,.075,4.838,.074,.009,
     1.003,.116,5.526,2.497,.044,.013,.666,1.559,1.024,.017,.003,.210,
     2.144,.152,.006,.084,.037,.123,.154,.038,.014,.010,.014,.020,
     3.006,.005,0.0,.011,0.0,.042,0.0,.023,.006,0.0,.003,.006,.273,.048,
     4.041,2.043,1.770,.028,.004,.129,.425,.008,.034,.500,.585,.009,
     5.007,.085,.204,.003,0.0,.020,.154,.101,.006,.049,.106,.003,.010,
     6.052,.021,.004,.028,.062,.005,.019,.005,.017,.044,.006,.013,.045,
     7.021,0.0,.004,.026,.003,.163,7.208,2.600,.073,.069,2.731,1.610,
     8.073,.005,.164,.556,.210,.016,.044,.080,.023,0.0,.005,.007,.009,
     9.011,.419,.320,.008,0.0,.108,.112,.017,.021,.017,.003/
C     SR = COEFFICIENTS S FOR RADIUS
      DATA  SR   /28.,6.,18.,5.,94.,2359.,69.,16.,4.,160.,
     16842.,869.,52.,21.,1045.,1497.,194.,19.,6.,376.,196.,94.,6.,
     2163.,59.,141.,26.,80.,25.,14.,12.,42.,12.,4.,4.,24.,6.,44.,
     312.,33.,13.,4.,8.,8.,150.,28.,52.,2057.,151.,31.,6.,168.,215.,
     46.,49.,478.,105.,10.,12.,107.,89.,3.,5.,30.,139.,27.,10.,60.,
     538.,5.,15.,45.,8.,6.,34.,17.,8.,15.,0.0,20.,9.,5.,15.,5.,22.,
     66.,4.,0.0,5.,208.,7067.,244.,80.,103.,4026.,1459.,8.,9.,281.,803.,
     7174.,29.,74.,113.,17.,3.,10.,12.,14.,15.,429.,8.,8.,3.,162.,
     8112.,0.0,32.,17.,4./
C     SLA = COEFFICIENTS S FOR LATITUDE
      DATA  SLA   /.029,.005,.092,.007,.023,.012,.067,.014,.014,
     1.008,.210,.007,.004,.006,.031,.012,.009,.019,.006,.004,.004,.010,
     2.008,.008,.007,.007,.017,.016,.023,.166,.006,.018,.006,.006/
C     AL = PHASE ANGLE K FOR LONGITUDE
      DATA AL    /243.,225.,357.,326.,296.6,299.101667,207.9,
     1249.,162.,148.9,148.313333,315.943333,311.4,176.,177.71,345.25333,
     2318.15,315.,198.,206.2,195.4,343.8,322.,235.6,221.8,195.3,359.6,
     3264.1,253.,230.,12.,294.,279.,288.,0.0,322.,0.0,259.2,0.0,48.8,
     4351.,0.0,18.,218.,217.7,260.3,346.,343.888,200.402,148.,284.,
     5294.2,338.88,7.,71.,105.18,334.06,325.,172.,54.6,100.8,18.,0.0,
     6186.,227.4,96.3,301.,176.5,222.7,72.,307.,348.9,215.2,57.,298.,
     7346.,68.,111.,338.,59.,105.9,232.,184.,227.8,309.,0.0,243.,113.,
     8198.,198.6,179.532,263.217,276.3,80.8,87.145,109.493,252.6,158.,
     9170.5,82.65,98.5,259.,168.2,77.7,93.,0.0,259.,164.,71.,105.,
     1100.58,269.46,270.,0.0,290.6,293.6,277.,289.,291.,288./
C     AR = PHASE ANGLE K FOR RADIUS
      DATA  AR   /335.,130.,267.,239.,205.,209.080,348.5,
     1330.0,90.,58.4,58.318,226.7,38.8,90.,87.570,255.25,49.5,43.,
     290.,116.28,105.2,254.8,59.,145.4,132.2,105.4,270.,174.3,164.,
     3135.,284.,203.5,194.,166.,135.,234.,218.,169.7,222.,138.7,261.,
     4256.,293.,130.,127.7,347.,255.4,253.828,295.,234.3,180.,203.5,
     5249.,90.,339.7,15.17,65.9,53.,90.,324.6,11.,108.,217.,95.7,137.3,
     6188.,209.,86.2,132.9,349.,217.,259.7,310.,329.,208.1,257.,337.,
     723.,0.0,30.,21.,143.,94.,143.,220.,261.,153.,0.0,112.,112.,
     889.545,338.6,6.5,350.5,357.108,19.466,263.000,69.,81.2,352.56,
     98.6,170.,79.9,347.7,3.,252.,169.,76.,343.,11.,10.6,353.,0.0,
     1198.,200.6,203.1,0.0,200.1,201.,194./
C     ALA = PHASE ANGLE FOR LATITUDE
      DATA  ALA   /145.,323.,93.7,262.,173.,149.,123.,111.,201.,
     1187.,151.8,153.,296.,232.,1.8,180.,27.,18.,288.,57.,57.,61.,90.,
     2346.,188.,180.,273.,180.,268.,265.5,171.,267.,260.,280./
C     T = TIME IN CENTURIES FROM 1900.0 (2415020.0)
C     TP = TIME IN YEARS FROM 1850.0
      REGRAD = DEGRAD
      T=(DJ-2415020.0D0)/36525.D0
      TP=(DJ-2396758.203D0)/365.25D0
      T2=T*T
      T3=T2*T
      S=T
C     COMPUTE POLYNOMIALS FOR MEAN ELEMENTS
      EL(1)=1.00000023D0
      EL(2)=.01675104D0-.00004180D0*T-.000000126D0*T2
      EL(3)=23.D0+(1628.26D0-46.845D0*T-.0059D0*T2+.00181D0*T3)/3600.D0
      EL(4)=0.0D0
      EL(5)=281.D0+(795.0D0+6189.03D0*T+1.63D0*T2+.012D0*T3)/3600.D0
      EL(6)=0.0D0
      EL(7)=DJ
      EL(8)=(1295977.432D0-.000403D0*T)/(3600.D0*365.25D0)
      EL(9)=279.D0+(2508.04D0+129602768.13D0*T+1.089D0*T2)/3600.D0
      EL(10)=EL(9)-EL(5)
      EL(13)=18.D0+(2325.836D0+8640184.542D0*T+.0929D0*T2)/3600.D0
      CALL CALCMODULO(EL(10),360.D0)
      GRAD=EL(10)*DEGRAD
      E(1)=EL(2)
      E(2)=E(1)*E(1)
      E(3)=E(2)*E(1)
      E(4)=E(3)*E(1)
      E(5)=E(4)*E(1)
      E(6)=E(5)*E(1)
      E(7)=E(6)*E(1)
      E(8)=E(7)*E(1)
C     COMPUTE EQUATION OF CENTER ,EL(12)
      EL(12)=RADDEG*(
     1+DSIN(1.0D0*GRAD)*(2.D0*E(1)-.25D0*E(3)+5.D0/96.D0*E(5)
     1                                       +107.D0/4608.D0*E(7))
     2+DSIN(2.0D0*GRAD)*(1.25D0*E(2)-11.D0/24.D0*E(4)+17.D0/192.D0*E(6)
     2                                       +43.D0/5760.D0*E(8))
     3+DSIN(3.0D0*GRAD)*(13.D0/12.D0*E(3)-43.D0/64.D0*E(5)
     3                                       +95.D0/512.D0*E(7))
     4+DSIN(4.0D0*GRAD)*(103.D0/96.D0*E(4)-451.D0/480.D0*E(6)
     4                                       +4123.D0/11520.D0*E(8))
     5+DSIN(5.0D0*GRAD)*(1097.D0/960.D0*E(5)-5957.D0/4608.D0*E(7))
     6+DSIN(6.0D0*GRAD)*(1223.D0/960.D0*E(6)-7913.D0/4480.D0*E(8))
     7+DSIN(7.0D0*GRAD)*(47273.D0/32256.D0*E(7)))
C     COMPUTE KEPLERIAN PART OF LOG(R) ,R0
      SMALOG=+0.00000010D0
      R0=     SMALOG+0.43429448190325183D0*
     1                (+(.25D0*E(2)+1.D0/32.D0*E(4)+1.D0/96.D0*E(6)
     1                                     +5.D0/1024.D0*E(8))
     1+DCOS(1.0D0*GRAD)*(-E(1)+.375D0*E(3)+1.D0/64.D0*E(5)
     1                                     +127.D0/9216.D0*E(7))
     2+DCOS(2.0D0*GRAD)*(-.75D0*E(2)+11.D0/24.D0*E(4)-3.D0/64.D0*E(6)
     2                                       +9.D0/640.D0*E(8))
     3+DCOS(3.0D0*GRAD)*(-17.D0/24.D0*E(3)+77.D0/128.D0*E(5)
     3                                       -743.D0/5120.D0*E(7))
     4+DCOS(4.0D0*GRAD)*(-71.D0/96.D0*E(4)+129.D0/160.D0*E(6)
     4                                       -387.D0/1280.D0*E(8))
     5+DCOS(5.0D0*GRAD)*(-523.D0/640.D0*E(5)+10039.D0/9216.D0*E(7))
     6+DCOS(6.0D0*GRAD)*(-899.D0/960.D0*E(6)+6617.D0/4480.D0*E(8))
     7+DCOS(7.0D0*GRAD)*(-355081.D0/322560.D0*E(7)))
      EL(11)=10.0D0**R0
      CALL CALCMODULO(EL(5),360.D0)
      CALL CALCMODULO(EL(9),360.D0)
      CALL CALCMODULO(EL(13),24.D0)
C     COMPUTE MEAN ANOMALIES OF PERTURBING PLANETS
      GME=248.070D0+1494.72350D0*TP
      GVE=114.500D0+ 585.17493D0*TP
      GMA=109.856D0+ 191.39977D0*TP
      GJU=148.031D0+  30.34583D0*TP
      GSA=284.716D0+  12.21794D0*TP
C     COMPUTE PERIODIC PERTURBATIONS FOR LONGITUDE AND LOG(R)
      DV=0.0D0
      DR=0.0D0
      DO 100 I=1,120
      IF(I.LE.4) GPL=GME
      IF(I.GE.5.AND.I.LE.43) GPL=GVE
      IF(I.GE.44.AND.I.LE.88) GPL=GMA
      IF(I.GE.89.AND.I.LE.109) GPL=GJU
      IF(I.GE.110) GPL=GSA
      RJ=JLR(I)
      RI=ILR(I)
      ARG=RJ*GPL+RI*EL(10)
      ARV=(ARG-AL(I))*DEGRAD
      ARR=(ARG-AR(I))*DEGRAD
      DV=DV+DBLE(SL(I)*COS(ARV))
 100  DR=DR+DBLE(SR(I)*COS(ARR))
C     COMPUTE PERIODIC PERTURBATIONS FOR LATITUDE
      DB=0.0D0
      DO 200 I=1,34
      IF(I.LE.22) GPL=GVE
      IF(I.GE.23.AND.I.LE.25) GPL=GMA
      IF(I.GE.26.AND.I.LE.32) GPL=GJU
      IF(I.GE.33) GPL=GSA
      RJ=JLA(I)
      RI=ILA(I)
      ARG=(RJ*GPL+RI*EL(10)-ALA(I))*DEGRAD
 200  DB=DB+DBLE(SLA(I)*COS(ARG))
      DV=DV+.266D0*SIN((31.8+119.0*S)*REGRAD)
     1     +6.40D0*SIN((231.19+20.20*S)*REGRAD)
     2+(1.882-.016*T)*SIN((57.24+150.27*S)*REGRAD)
     3+0.20*DCOS((15.*GMA-8.*EL(10))*DEGRAD)
     4-0.03*DSIN((15.*GMA-8.*EL(10))*DEGRAD)
      EL(21)=334.D0+109.D0*T+(1186.40D0+122.52D0*T-37.17D0*T2-.045D0*T3)
     1/3600.D0+11.D0*TWOPI*RADDEG*T
      CALL CALCMODULO(EL(21),360.D0)
      EL(14)=270.D0+307.D0*T+(1562.99D0+3179.31D0*T-4.08D0*T2+.68D-2*T3)
     1/3600.D0+ 1336.D0*TWOPI*RADDEG*T
      CALL CALCMODULO(EL(14),360.D0)
      EL(15)=296.D0+198.D0*T
     1      +(376.59D0+3056.79D0*T+33.09D0*T2+.0518D0*T3)/3600.D0
     2     +(1325.D0*T*TWOPI*RADDEG)
      CALL CALCMODULO(EL(15),360.D0)
      EL(17)=259.D0-134.D0*T+(659.79D0-511.23D0*T+7.48D0*T2+.008D0*T3)
     1/3600.D0-5.D0*TWOPI*RADDEG*T
      CALL CALCMODULO(EL(17),360.D0)
      EL(16)=EL(14)-EL(17)
      CALL CALCMODULO(EL(16),360.D0)
      EL(18)=(5489.90D0-0.00364D0*T)/3600.D0
      AD=EL(14)-EL(9)
      AUP=EL(9)-EL(17)
      DV=DV+6.454*DSIN(AD*DEGRAD)
     1     +0.013*DSIN(3.*AD*DEGRAD)
     2     +0.177*DSIN((AD+EL(15))*DEGRAD)
     3     -0.424*DSIN((AD-EL(15))*DEGRAD)
     4     +0.039*DSIN((3.*AD-EL(15))*DEGRAD)
     5     -0.064*DSIN((AD+EL(10))*DEGRAD)
     6     +0.172*DSIN((AD-EL(10))*DEGRAD)
     7     -0.013*DSIN((AD-EL(15)-EL(10))*DEGRAD)
     8     -0.013*DSIN(2.*AUP*DEGRAD)
      DR=(+1336.*DCOS(DEGRAD*(AD))
     1     +0003.*DCOS(DEGRAD*(3.*AD))
     2     +0037.*DCOS(DEGRAD*(AD+EL(15)))
     3     -0133.*DCOS(DEGRAD*(AD-EL(15)))
     4     +0008.*DCOS(DEGRAD*(3.*AD-EL(15)))
     5     -0014.*DCOS(DEGRAD*(AD+EL(10)))
     6     +0036.*DCOS(DEGRAD*(AD-EL(10)))
     7     -0003.*DCOS(DEGRAD*(AD-EL(15)-EL(10)))
     8     +0003.*DCOS(DEGRAD*(2.*AUP)))*10.0D0+DR
      DB=  +.576*DSIN(DEGRAD*(EL(16)))
     1     +.016*DSIN(DEGRAD*(EL(16)+EL(15)))
     2     -.047*DSIN(DEGRAD*(EL(16)-EL(15)))
     3     +.021*DSIN(DEGRAD*(EL(16)-2.*AUP))
     4     +.005*DSIN(DEGRAD*(EL(16)-2.*AUP-EL(15)))
     5     +.005*DSIN(DEGRAD*(EL(16)+EL(10)))
     6     +.005*DSIN(DEGRAD*(EL(16)-EL(10)))-DB
C     COMPUTE THE COORDINATES
 600  C(1)=10.D0**(R0+DR*1.D-9)
      C(2)=EL(9)+DV/3600.D0+EL(12)
      CALL CALCMODULO(C(2),360.D0)
      C(4)=C(2)*DEGRAD
      C(3)=DB/3600.D0
      C(5)=C(3)*DEGRAD
      RETURN
      END
c
c----------------------------------------------------------------------
c
c 
c Thomas Forbriger 24/05/2002:
c This subroutine was called MODULO. But this name conflicts with an intrinsic
c function that is reserved by g77 (and which was introduced with the
c Fortran90 standard). To resolve the conflict, I renamed the subsroutine.
c 
      SUBROUTINE CALCMODULO(A,B)
C CALCMODULO SPECIAL PURPOSE SUBROUTINE IN BROUCKE EPHEMERIS SYSTEM
C     A AND B ARE INPUT (B POSITIVE)
C     A IS OUTPUT (BETWEEN 0 AND B)
C     B IS NOT CHANGED BY THE SUBROUTINE
      DOUBLE PRECISION A,B,C
      N=IDINT(A/B)
      C=DBLE(FLOAT(N))
      A=A-C*B
      IF(A.LT.0.0D0) A=A+B
      RETURN
      END
c
c----------------------------------------------------------------------
c
      SUBROUTINE CRMOON(DATE,COODEK,COORAS,COOPAR)
C
C COMPUTES APPARENT GEOCENTRIC COORDINATES OF THE MOON .
C
C     COOR(1)=LONGITUDE OF MOON(RADIANS,MEAN EQUINOX OF DATE)
C     COOR(2)=LATITUDE  OF MOON(RADIANS,MEAN EQUINOX OF DATE)
C     COOR(3)=PARALLAX  OF MOON(RADIANS,MEAN EQUINOX OF DATE)
C     COOR(4)=NUTATION CORRECTION IN LONGITUDE (RADIANS)
C     COOR(5)=NUTATION CORRECTION IN OBLIQUITY (RADIANS)
C     COOR(L)=LONGITUDE OF MOON (RADIANS,TRUE EQUINOX OF DATE)
C     COOR(7)=MEAN OBLIQUITY OF ECLIPTIC (RADIANS)
C     COOR(8)=TRUE OBLIQUITY OF ECLIPTIC (RADIANS)
C     COOR(9,10,11)=X,Y,Z=RECTANGULAR ECLIPTIC COORDINATES OF MOON
C                   WITH TRUE ECLIPTIC AND EQUINOX OF DATE
C                   THE UNITS ARE EARTH RADII
C     COOR(12,13,14)=X,Y,Z=RECTANGULAR EQUATORIAL COORDINATES OF MOON
C                   IN EARTH RADII,WITH TRUE EQUATOR OF DATE
C     COOR(15)=TRUE  RIGHT ASCENSION OF MOON (RADIANS,EQUAT.OF DATE)
C     COOR(16)=TRUE  DECLINATION OF MOON (RADIANS,EQUATOR OF DATE)
      DOUBLE  PRECISION DATE,COOR(16),RAD,T,SINP,COSL,SINL,COSB,SINB,
     *COSE,SINE
      DOUBLE PRECISION  COODEK,COORAS,COOPAR
      DATA RAD/.1745329251994330D-1/
      CALL LUNAR(DATE,COOR(1),COOR(2),COOR(3))
      CALL NUTAN(DATE,COOR(4),COOR(5))
      COOR(6)=COOR(1)+COOR(4)
      T=(DATE-2415020.0D0)/36524.21988D0
C     T=TIME IN TROPICAL CENTURIES FROM 1900
      COOR(7)=(23.452294D0-.0130125D0*T-.164D-5*T**2+.503D-6*T**3)*RAD
      COOR(8)=COOR(7)+COOR(5)
      SINP=DSIN(COOR(3))
      COSL=DCOS(COOR(6))
      SINL=DSIN(COOR(6))
      COSB=DCOS(COOR(2))
      SINB=DSIN(COOR(2))
      COOR(09)=COSL*COSB/SINP
      COOR(10)=SINL*COSB/SINP
      COOR(11)=SINB     /SINP
      COSE=DCOS(COOR(8))
      SINE=DSIN(COOR(8))
      COOR(12)=COOR(09)
      COOR(13)=COOR(10)*COSE-COOR(11)*SINE
      COOR(14)=COOR(10)*SINE+COOR(11)*COSE
      CALL ARC(COOR(12),COOR(13),COOR(15))
      COOR(16)=COOR(12)**2+COOR(13)**2
      COOR(16)=DSQRT(COOR(16))
      COOR(16)=DATAN(COOR(14)/COOR(16))
       COODEK=COOR(16)
      COORAS=COOR(15)
      COOPAR=COOR(3)
      RETURN
      END
c
c----------------------------------------------------------------------
c
      SUBROUTINE LUNAR(DATE,A,B,C)
COMPUTES GEOCENTRIC COORDINATES OF THE MOON WITH BROWN'S LUNAR THEORY
C  PRECISION=  2.SEC OF ARC IN LONGITUDE
C              1. SEC OF ARC IN LATITUDE
C              .1 SEC OF ARC IN PARALLAXE
C  INPUT =  DATE =JULIAN DAY IN EPHEMERIS TIME (DOUBLE PRECISION)
C  OUTPUT= CLONG = LONGITUDE
C          BETA  = LATITUDE
C          PAR   = PARALLAX
C ALL OUTPUT IS IN RADIANS  W.R. TO MEAN EQUINOXE OF DATE
C TO COMPUTE EARTH-MOON DISTANCE, USE
C            R =(EARTH  EQUATORIAL  RADIUS)/(SINE OF PARALLAX)
      DIMENSION ANGLE(5),IX(4,61),X(61),IY(4,48),Y(48),IZ(4,30),Z(30),
     1 EN(10),IN(4,10),EG(13),IG(4,13),ADD(3)
      DOUBLE PRECISION DATE,DD,DD2,DD3,PI,RASEC,RADIAN,ANGLE,ADD,A,B,C,D
C  SUPPLY DATE (JULIAN DATE +DECIMAL OF DAY)
      DATA IX/ 1,0,0,0, 1,0,0,-2, 0,0,0,2, 2,0,0,0, 0,+1,0,0, 0,0,2,0, 2
     1,0,0,-2, 1,1,0,-2, 1,0,0,2, 0,1,0,-2, 1,-1,0,0, 0,0,0,1, 1,1,0,0,
     20,0,2,-2, 1,0,2,0, 1,0,-2,0, 1,0,0,-4, 3,0,0,0, 2,0,0,-4, 1,-1,0,-
     32, 0,1,0,2, 1,0,0,-1, 0,1,0,1, 1,-1,0,2, 2,0,0,2, 0,0,0,4, 3,0,0,-
     42,2,-1,0,0, 1,0,-2,-2, 2,1,0,-2, 1,0,0,1, 0,2,0,-2, 2,1,0,0,0,2,0,
     50, 1,2,0,-2, 1,0,-2,2, 0,0,2,2, 1,1,0,-4, 2,0,2,0,1,0,0,-3, 1,1,0,
     6 2, 2,1,0,-4, 2,-1,0,-2, 1,-2,0,0, 1,-2,0,-2, 0,1,2,-2, 1,0,0,4,
     7 4,0,0,0, 0,1,0,-4, 2,0,0,-1, 0,1,-2,2, 2,0,-2,0, 1,1,0,1, 2,0,0,
     8   -3, 3,0,0,-4, 2,-1,0,2, 1,2,0,0, 1,-1,0,-1, 3,0,0,2, 1,0,2,2, 4
     9,0,0,-2 /
      DATA IY/1,0,0,0, 1,0,0,-2, 0,0,0,2, 2,0,0,0, 1,0,0,2, 1,1,0,-2, 0,
     11,0,-2, 2,0,0,-2, -1,1,0,0, 0,1,0,0, 1,1,0,0, 0,0,0,1, -1,0,2,0, 0
     2,0,2,-2, 3,0,0,0, 1,0,0,-4, 2,0,0,-4,-1,1,0,-2, 0,1,0,2,-1,1,0,+2,
     3 0,1,0,1,  3,0,0,-2, 0,2,0,-2, 2,0,0,2, 0,0,0,4, 1,0,0,1, 1,1,0,2,
     4 2,-1,0,0, 2,1,0,0, 1,1,0,-4, 1,0,2,-2, 2,1,0,-2, 1,0,0,4, 0,1,0,-
     5 4, 1,2,0,-2, 1,0,0,-3, 0,0,0,3,  4,0,0,0, 1,0,0,-1, -1,0,2,-2,
     6 2,-1,0,2, 3,0,0,2, 2,1,0,-4, -1,2,0,2, -1,2,0,0, -1,1,0,4, 2,0,0,
     7 -1, -1,2,0,-2 /
      DATA IZ /1,0,0,0, 1,0,0,-2, 0,0,0,2, 2,0,0,0, 1,0,0,2, 0,1,0,-2, 1
     1,1,0,-2, 1,-1,0,0, 0,0,0,1, 1,1,0,0 , 1,0,-2,0, 3,0,0,0, 1,0,0,-4,
     2 0,1,0,0, 2,0,0,-4, 0,1,0,2, 2,0,0,-2, 2,0,0,2, 0,0,0,4, 1,-1,0,2,
     3 1,-1,0,-2, 0,1,0,1, 2,-1,0,0, 3,0,0,-2, 1,0,0,1, 0,0,2,-2, 2,1,0,
     40, 0,2,0,-2, 1,0,2, -2,  1,1,0,-4/
      DATA IN / 0,0,1,-2, 1,0,1,-2, -1,0,1,-2,-2,0,1,0, 0,1,1,-2, -1,0,1
     1,0,0,-1,1,-2,1,0,1,-4,0,0,1,-4,-2,0,1,-2/
      DATA IG /2,0,0,-2, 1,1,0,-2, -1,1,0,-2, 3,0,0,0, 0,1,0,0, 1,1,0,2,
     1 0,0,0,1, 0,2,0,-2, 0,0,0,2, 1,1,0,-4, 1,0,0,4, 1,0,0,1,
     2 -1,1,0,2/
      DATA X /22639.6, -4586.5, 2369.9, 769.0, -668.1, -411.6, -211.6, -
     1206.0, 192.0, -165.1, 147.7, -125.2, -109.7, -55.2, -45.1, +39.5,
     2-38.4, +36.1, -30.8, +28.5, -24.4, +18.6, 18.0, 14.6, 14.4, 13.9,
     3-13.2, 9.7, 9.4, -8.6, -8.5, -8.1, -7.6, -7.5, -7.4, -6.4, -5.7, -
     44.4, -4.0,+3.2,-2.9,-2.7,-2.5,+2.6,+2.5,-2.1,+2.0,+1.9,-1.8,+1.8,-
     5 1.4,-1.3,+1.3,+1.2,-1.1,+1.2,-1.1,-1.1,+1.0,-1.0,-0.9 /
      DATA  Y/ 22609., -4578.1, 2373.4, 768., 192.7, -182.4, -165., -152
     1.5, -138.8, -127.0, -115.2, -112.8, -85.1, -52.1, 50.6, -38.6, -34
     2.1, -31.7, -25.1, -23.6, 17.9, -16.4, -16.4,+14.78,+14.06,-13.51,-
     311.75,+11.67,-10.56,-9.66,-9.52,-7.59,+6.98,-6.46,-6.12,+5.44,-4.0
     41,+3.60,+3.59,+3.37,+3.32,+2.96,-2.54,-2.40,-2.32,-2.27,+2.01,-1.8
     52 /
      DATA Z /           +186.5, 34.3, 28.2, 10.2, 3.1, 1.9, 1.5, 1.2, -
     11.0, -0.9,-.71,+.62,+.60,-.40,+.37,-.30, -.30,+.28, +.26, +.23, -.
     2 23, +.15, +.13, -.12, -.11,-.11,-.10,+.09,-.08,+.07 /
      DATA EN /-526.0,44.3,-30.6,-24.6,-22.6,20.6,11.0,-6.0,-3.3
     1,-2.0/
      DATA EG/5.7,2.1,-1.5,-1.3,-1.3,0.8,-0.7,-0.7,0.6,-0.5,-0.4,0.4,-0.
     14/
      PI = 3.141592653589D0
      TWOPI = 2.*PI
      RADIAN = 180.D0/PI
      RASEC = PI/(180.D0*3600.D0)
      D = DATE - 2415020.D0
      DD=D/10000.0D0
      DD2 = DD*DD
      DD3 = DD2*DD
      ANGLE(1)=270.434164D0 +13.1763965268D0*D -.0000850*DD2
     1 +.000000039D0*DD3
      ANGLE(2) = 279.696678D0 +.9856473354D0*D+.00002267*DD2
      ANGLE(3) = 334.329556D0 +.1114040803D0*D - .0007739*DD2
     1 -.00000026D0*DD3
      ANGLE(4) = 259.183275D0 -.0529539222D0*D +.0001557*DD2
     1 -.00000005*DD3
      ANGLE(5) = 281.220833D0 +.0000470684D0*D +.0000339*DD2
     1 +.00000007*DD3
C ANGLE 1 IS MEAN LONGITUDE OF MOON AT EPOCH
C ANGLE 2 IS MEAN LONGITUDE OF SUN AT EPOCH
C ANGLE 3 IS LONGITUDE OF LUNAR PERIGEE AT EPOCH
C ANGLE 4 IS LONGITUDE OF ASCENDING NODE AT EPOCH
C ANGLE 5 IS LONGITUDE OF SOLAR PERIGEE AT EPOCH
      DO 01 I = 1,5
      J = ANGLE(I)/360.D0
      ANGLE(I) = (ANGLE(I) - 360*J)/RADIAN
   01 IF ( ANGLE(I).LT.0.0) ANGLE(I) = ANGLE(I)+2.*PI
      ADD(1) = 2.*PI*(.14222222D0  + .000001536238D0*D)
      ADD(2) = 2.*PI*(.48398132D0   -.000147269147D0*D)
      ADD(3) = 2.*PI*(.53733431D0 -.000010104982D0*D)
      EEL=ANGLE(1)+RASEC*(14.27*DSIN(ADD(3))+7.26*DSIN(ANGLE(4))+.84*DSI
     1N(ADD(1)))
C TWO ADDITIVE TERMS IN ANODE (BELOW) ARE ADDED AS ROUGH APPROXIMATION
      ANODE=ANGLE(4)+RASEC*(96.*DSIN(ANGLE(4))+(15.6+1.9)*DSIN(ADD(2)))
      OMOON=ANGLE(3)+RASEC*(-2.10*DSIN(ADD(1))-2.08* SIN(ANODE)-.84*DSIN
     1(ADD(2)))
      EL = EEL - OMOON
      ELP = ANGLE(2) - ANGLE(5)
      F = EEL - ANODE
      DEE = EEL - ANGLE(2)
      CLONG = EEL
      S = F
      PAR = 3422.7*RASEC
      DO  11  K=1,61
   11 CLONG=CLONG    + X(K)*RASEC*SIN(IX(1,K)*EL +IX(2,K)*ELP + IX(3,K)
     1*F + IX(4,K)*DEE )
      IF (CLONG.GE.TWOPI) CLONG = CLONG - TWOPI
      IF (CLONG.LT. 0.0) CLONG = CLONG + TWOPI
      DO  12  K=1,48
   12 S = S +          Y(K)*RASEC*SIN(IY(1,K)*EL +IY(2,K)*ELP + IY(3,K)
     1*F + IY(4,K)*DEE )
      SCREW = (1. -.0004664*COS(ANODE) -.0000754*COS(ANODE+4.82))*SIN(S)
      BETA  = (18519.7*SCREW -6.2*SIN(3.*S))*RASEC
      DO  13  K=1,30
   13 PAR    = PAR    +Z(K)*RASEC*COS(IZ(1,K)*EL +IZ(2,K)*ELP + IZ(3,K)
     1*F + IZ(4,K)*DEE )
      DO  14  K=1,10
   14 BETA   =BETA   +EN(K)*RASEC*SIN(IN(1,K)*EL +IN(2,K)*ELP + IN(3,K)
     1*F + IN(4,K)*DEE )
      G1C = 0.
      DO  15  K=1,13
   15 G1C = G1C+RASEC*EG(K)*COS(IG(1,K)*EL +IG(2,K)*ELP +IG(3,K)*F +IG(4
     1,K)*DEE)
      BETA = BETA + G1C*SIN(S)
      A = CLONG
      B = BETA
      C = PAR
      RETURN
      END
c
c----------------------------------------------------------------------
c
      SUBROUTINE NUTAN(XJD,XNUTL,XNUTO)
C     COMPUTES NUTATION IN LONGITUDE AND OBLIQUITY
C  INPUT=XJD= TIME IN JULIAN DAYS
C  OUTPUT=XNUTL=NUTATION IN LONGITUDE (IN  RADIANS)
C     AND XNUTO=NUTATION IN OBLIQUITY (IN  RADIANS)
      DOUBLE PRECISION  XJD,PL,PO,XNUTL,XNUTO
      DOUBLE PRECISION A(5,4),FA(5)
      DOUBLE PRECISION T
      REAL XL(13),XLP(13),XFX(13),XD(13),XN(13),SLC(13),SLT(13),COC(13),
     *COT(13)
      REAL SA(5)
      DOUBLE PRECISION TWOPI
      DATA TWOPI /6.283185307179586D00/
      DATA A /
     1+.82251280093D0,.99576620370D0,.03125246914D0,
     2 .97427079475D0,.71995354167D0,
     3.036291645684716D0,.002737778519279D0,.036748195691688D0,
     4 .033863192198393D0,-.000147094228332D0,
     5+1913865.D-20,-31233.D-20,-668609.D-20,-299023.D-20,+432630.D-20,
     6 +8203.D-25,-1900.D-25,-190.D-25,+1077.D-25,+1266.D-25 /
      DATA XL /+0.,+0.,+0.,+0.,+0.,+1.,+0.,+0.,+1.,+0.,+0.,+0.,+0./
      DATA XLP/+0.,+0.,+0.,+0.,+1.,+0.,+1.,+0.,+0.,-1.,+0.,+2.,+2./
      DATA XFX/+0.,+2.,+0.,+2.,+0.,+0.,+2.,+2.,+2.,+2.,+2.,+0.,+2./
      DATA XD /+0.,-2.,+0.,+0.,+0.,+0.,-2.,+0.,+0.,-2.,-2.,+0.,-2./
      DATA XN /+1.,+2.,+2.,+2.,+0.,+0.,+2.,+1.,+2.,+2.,+1.,+0.,+2./
      DATA  SLC  /
     *-17.2327,-1.2729,+.2088,-.2037,+.1261,+.0675,-.0497,-.0342,-.0261,
     *+.0214,+.0124,+.0016,-.0015/
      DATA  SLT  /
     *-.01737,-.00013,+.00002,-.00002,-.00031,+.00001,+.00012,-.00004,
     *+.00000,-.00005,
     *+.00001,-.00001,+.00001/
      DATA  COC  /
     *+ 9.2100,+0.5522,-.0904,+.0884,+.0000,+.0000,+.0216,+.0183,+.0113,
     *-.0093,-.0066,+.0000,+.0007/
      DATA  COT  /
     *+.00091,-.00029,+.00004,-.00005,+.00000,+.00000,-.00006,+.00000,
     *-.00001,+.00003,
     *+.00000,+.00000,+.00000/
C     *****************************************************************0
      T=XJD-2415020.0D0
      TC=T/36525.0D0
      DO 12 I=1,5
      FA(I)=DMOD(((A(I,4)*T+A(I,3))*T+A(I,2))*T,1.0D0)+A(I,1)
      FA(I)=DMOD(FA(I),1.0D0)*TWOPI
   12 SA(I)=FA(I)
      PL=0.0
      PO=0.0
      DO 15 I=1,13
      ARG=XL(I)*SA(1)+XLP(I)*SA(2)+XFX(I)*SA(3)+XD(I)*SA(4)+XN(I)*SA(5)
      PO=PO+(COC(I)+COT(I)*TC)*COS(ARG)
      PL=PL+(SLC(I)+SLT(I)*TC)*SIN(ARG)
 15   CONTINUE
      XNUTL=PL*TWOPI/1296000.D0
      XNUTO=PO*TWOPI/1296000.D0
      RETURN
      END
      SUBROUTINE ARC(COSA,SINA,ANGLE)
      DOUBLE PRECISION COSA,SINA,ANGLE
      IF(COSA)310,311,320
  311 IF(SINA) 312,313,313
  312 ANGLE=4.712388980384690D0
      GO TO 350
  313 ANGLE=1.570796326794897D0
      GO TO 350
  310 ANGLE=DATAN(SINA/COSA)+3.141592653589793D0
      GO TO 350
  320 ANGLE=DATAN(SINA/COSA)
      IF(SINA) 315,350,350
  315 ANGLE=ANGLE+6.283185307179586D0
  350 RETURN
      END
c      
c----------------------------------------------------------------------
c
      SUBROUTINE GSTIME(UT,AGST)
C  COMPUTES GREENWICH SIDEREAL TIME,WHEN UNIVERSAL TIME IS GIVEN
C  INPUT=UT=UNIVERSAL TIME IN JULIAN DAYS
C  OUTPUT=MGST=MEAN GREENWICH SIDEREAL TIME,IN HOURS
C         AGST=APPARENT GREENWICH SIDEREAL TIME,IN HOURS
C  AGST=HOUR ANGLE OF VERNAL EQUINOX + 12.0 HOURS
C         EQEQ=EQUATION OF EQUINOXES,IN SECONDS
C         OBL =TRUE OBLIQUITY OF THE ECLIPTIC ,IN DEGREES
      DOUBLE PRECISION UT,MGST,AGST,EQEQ,    RU,T,T2,A1,B1,XL,XO,MOBL,T3
     1,OBL,RAD
      DATA RAD/.0174532925199433D0/
      A1=(UT-2415020.0D0)
      T=A1/36525.0D0
      T2=T*T
      T3=T2*T
      RU=18.0D0+(2325.836D0+8640184.542D0*T+0.0929D0*T2)/3600.0D0
      I1=IDINT(A1)
      B1=DBLE(FLOAT(I1))
      MGST=(A1-B1)*24.0D0+12.0D0+RU
      MGST=DMOD(MGST,24.0D0)
      CALL NUTAN(UT,XL,XO)
      MOBL=23.D0+(1628.26D0-46.845D0*T-.0059D0*T2+.00181D0*T3)/3600.D0
      OBL=MOBL+XO/RAD
      EQEQ=XL*DCOS(RAD*OBL)/(RAD*15.0D0)
      AGST=MGST+EQEQ
      AGST=DMOD(AGST,24.0D0)
      RETURN
      END
c
c----------------------------------------------------------------------
c
      SUBROUTINE ETMUTC(DJ,Y)
C INPUT=DJ=TIME IN JULIAN YEARS RECKONED FROM THE FUNDAMENTAL EPOCH
C              (NOT LESS THAN  55.5 )
C OUTPUT=Y= DELTA   T =ET - UTC   IN SECONDS

C THE TABLE HAS TO BE EXTENDED,WHEN NEW DATA ARE AVAILABLE.CHANGE NTAB T
C     SOURCE OF INFORMATION: JET PROPULSION LABORATORY (DR.R.A.BROUCKE)
      DOUBLE PRECISION DJ,Y
      DIMENSION  TX(53),TY(53)
      DATA  TX/
     155.5    ,56.5     ,57.5     ,58.5     ,59.5     ,60.5     ,61.5  ,
     262.     ,62.5     ,63.      ,63.5     ,64.      ,64.5     ,65.   ,
     365.5    ,66.      ,66.5     ,67.      ,67.5     ,68.      ,68.25 ,
     468.5    ,68.75    ,69.      ,69.25    ,69.5     ,69.75    ,70.   ,
     570.25   ,70.5     ,70.75    ,71.      ,71.085   ,71.162   ,71.247,
     671.329  ,71.414   ,71.496   ,71.581   ,71.666   ,71.748   ,71.833,
     771.915  ,71.999   ,72.0     ,72.499   ,72.5     ,72.9999  ,73.0  ,
     873.9999 ,74.0     ,74.9999  ,75.0     /
      DATA  TY /
     131.59   ,32.06    ,31.82    ,32.69    ,33.05    ,33.16    ,33.59 ,
     234.032  ,34.235   ,34.441   ,34.644   ,34.95    ,35.286   ,35.725,
     336.16   ,36.498   ,36.968   ,37.444   ,37.913   ,38.39    ,38.526,
     438.76   ,39.      ,39.238   ,39.472   ,39.707   ,39.946   ,40.185,
     540.42   ,40.654   ,40.892   ,41.131   ,41.211   ,41.284   ,41.364,
     641.442  ,41.522   ,41.600   ,41.680   ,41.761   ,41.838   ,41.919,
     741.996  ,42.184   ,42.184   ,42.184   ,43.184   ,43.184   ,44.184,
     844.184  ,45.184   ,45.184   ,46.184   /
      NTAB=53
      IF(DJ-TX(NTAB))  11,12,12
   12 Y=TY(NTAB)
      RETURN
   11 DO  20  I=1,NTAB
      IF(DJ-TX(I))   21,22,20
   22 Y=TY(I)
      RETURN
   21 N=I-1
      GO  TO  23
   20 CONTINUE
   23 Y=(TY(N+1)*(DJ-TX(N))-TY(N)*(DJ-TX(N+1)))/(TX(N+1)-TX(N))
      RETURN
      END
c
c======================================================================
c source code of bfotide.f
c
c Copyright (c) 1959 by Jon Berger, Russ Evans, and Dan McKenzie
c Copyright (c) 1974 by Walter Zuern
c Copyright (c) 1978 by David Young
c
c Earth response to tidal forces based on Longmans code
c
c This program calculates the response of an elastic earth to tidal
c forces. The Earth's elasticity is defined by Love-numbers in
c subroutine TIDEPT. The program computes acceleration, strain and tilt.
c The calculation is based on ephemerides based on Longman's theory.
c
c See:
c I.M. Longman, 1959. Formulas for Computing the Tidal Accelerations due
c to the Moon and the Sun. Journal of Geophysical Research, Vol. 64, No.
c 12, 2351 - 2355.
c
c ----
c This program is free software; you can redistribute it and/or modify
c it under the terms of the GNU General Public License as published by
c the Free Software Foundation; either version 2 of the License, or
c (at your option) any later version. 
c 
c This program is distributed in the hope that it will be useful,
c but WITHOUT ANY WARRANTY; without even the implied warranty of
c MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
c GNU General Public License for more details.
c 
c You should have received a copy of the GNU General Public License
c along with this program; if not, write to the Free Software
c Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
c ----
c
      subroutine bfotide
c  this program uses TIDEPT to compute three components of the earth
c  tide signal on an elastic earth.
c  besides vital variables,format statements 108,109 should be modified
c  first differences are formed
      double precision ts,dt,t,tim69
      integer opt
      character*80 fname
      print*,'Enter output file name: '
      read(*,'(a)')fname
      open(3,file=fname)
c
      print*,' '
      print*,'Enter latitude and longitude of your station in '
      print*,'  decimal degrees: '
      read(*,*) glat, glong
c
      print*,' '
      print*,'Chose between - acceleration (e.g. gravity) (opt=1)'
      print*,'              - tilt (opt=2)'
      print*,'              - strain (opt=3)'
      print*,'Enter opt: '
      read(*,*)opt

      print*,' '
      print*,'Azimuth convention for sensors: '
      print*,'  for acceleration: east from north '
      print*,'  for strainmeter: east from north '
      print*,'          i.e. 0.0 deg is north strain'
      print*,'              45.0 deg is north-east strain'
      print*,'              90.0 deg is east strain'
      print*,'  for tiltmeter  : north from east, '
      print*,'          i.e. 0.0 deg is east tilt'
      print*,'              90.0 deg is north tilt'
      print*,' '
      print*,' Enter time step in seconds: '
      read(*,*)dt
c  timestep in hours
      dt=dt/3600.d0
c
      print*,' '
      print*,' Enter start time of synthetic tidal record. '
      print*,'   (for march 1. 1995 enter: 1995 3 1): '
      read(*,*)iyr,imonth,iday
c  elapse time of first point in hours since jan 01,1969,0.0 hrs GMT
      ts= TIM69(iyr,imonth,iday)
c
      print*,' '
      print*,' Set scale for output. '
      print*,'  if scale=1.e+6 then acceleration in microgals '
      print*,'                      tilt         in microrads '
      print*,'                      strain       in microstrain '
      print*,'  for nanogals and nanostrains use scale=1.e+9 '
      print*,'  for tilt in msecs arc use  scale=0.206264806e+09 '
      print*,' Enter scale: '
      read(*,*)scale
c     
      print*,' '
      print*,' Enter length of time series (hours): '
      read(*,*)xlen
      ndata = int(xlen/dt)
      print*,' You have asked for ',ndata,' samples. '
      t=ts
      print*,' '
      print*,' tides on an elastic earth model (earthtd)'
      print*,' '
      print*,'    north latitude =',glat
      print*,'    east longitude =',glong
      if (opt.eq.1) then
         print*,' Computing acceleration components: Z, N, E '
         print*,' gravity (gals*scale**(-1)) '
      elseif (opt.eq.2) then
         print*,' Computing tilt components: N, E '
         print*,' tilt (rads*scale**(-1)) '
      elseif (opt.eq.3) then
         print*,' Computing strain components: N, N-E, E '
         print*,' strain (strain*scale**(-1)) '
      endif
      print*,' scale= ',scale

      print*,' start of series at: ',ts,
     *       ' hours from JAN 01, 1969 0.0 hrs GMT'
      print*,' time step= ',dt,' hours. '
      print*,' '
      print*,' 1. point = 0000h GMT on',iyr,imonth,iday
c
c if tilt is also computed with 1.000e+06 for scale, then result is also
c in microgals
      lorder=0
      do  1  i=1,ndata
         if (opt.eq.1) then
c acceleration
            call tidept(t,xz,glat,glong,0.0,scale,lorder,1)
            call tidept(t,xn,glat,glong,90.0,scale,lorder,2)
            call tidept(t,xe,glat,glong,0.0,scale,lorder,2)
            xn = 981.0*xn
            xe = 981.0*xe
            write(3,'(f15.3,3f10.2)') t-ts,xz,xn,xe
         elseif(opt.eq.2) then
c tilt
            call tidept(t,xn,glat,glong,90.0,scale,lorder,2)
            call tidept(t,xe,glat,glong,0.0,scale,lorder,2)
            write(3,'(f15.3,2f10.2)') t-ts,xn,xe
         elseif(opt.eq.3) then
c strain
            call tidept(t,xn,glat,glong,90.0,scale,lorder,2)
            call tidept(t,xne,glat,glong,45.0,scale,lorder,2)
            call tidept(t,xe,glat,glong,0.0,scale,lorder,2)
            write(3,'(f15.3,3f10.2)') t-ts,xn,xne,xe
         endif

         t=t+dt
   1  continue
      close(3)
      stop
      end
c
c----------------------------------------------------------------------
c
      SUBROUTINE TIDEPT (TIME,RESULT,GLAT,GLONG,ORIENT,SCALE,
     * LORDER,OPT)
C    BERGER,EVANS,MCKENZIE
C MODIFIED BY YOUNG 16.1.78 TO RETURN STRAIN VALUE AT ONE TIME
C ONLY.  SEE SUBROUTINE EARTHTD FOR DETAILS OF VARIABLES.
C     STRAINMETER AZIMUTH IS POSITIVE EAST FROM NORTH
      REAL LAMDA,   LL,         H,K,L,KR,MU,MUT,MUL,MUTT,MULL,MUTL,ELL,
     1  ETT,ETL
      DOUBLE PRECISION  SAW,CAW,RBARR
      DOUBLE PRECISION CZ,SZ,Z,X,THFPSI,CNM,SNM,CW,SW,CNU,SNU,NU
      DOUBLE PRECISION TIME,TT,PSIG,PSIM,HR,AW
      DOUBLE PRECISION  PI20,HALFPI,TWOPI,AZT,HS,T2,PS,T,PSIS,HM,PM,NM,
     1  ES,SIG,LS,LM,TANP
      INTEGER OPT
      DIMENSION  H(6),K(6),L(6),KR(7),P(7),PP(7),PPP(7)
      H(1)=0.612
      H(2)=0.290
      H(3)=0.175
      H(4)=0.129
      H(5)=0.107
      H(6)=0.095
      K(1)=0.302
      K(2)=0.093
      K(3)=0.042
      K(4)=0.025
      K(5)=0.017
      K(6)=0.013
      L(1)=0.083
      L(2)=0.014
      L(3)=0.010
      L(4)=0.008
      L(5)=0.007
      L(6)=0.005
      JS=2
      JE=3
      IF(LORDER.EQ.0)  GO TO5
      JE=LORDER
      JS=JE
  5   CONTINUE
      GTSUN=0.
      TTSUN=0.
      STNSUN=0.
      LAMDA=GLONG
      THETA=90.0-GLAT
      AZS=-ORIENT
      AZT=-ORIENT
      PI20=62.83185307169D0
      HALFPI=1.570796326793D0
      TWOPI=6.283185307169D0
      RE=6.37122E+8
      G=982.02
      AZT=AZT*0.0174532925199D0
      AZS=AZS*0.0174532925199D0
      CAZT=COS(AZT)
      SAZT=SIN(AZT)
      CAZS=COS(AZS)
      SAZS=SIN(AZS)
      TT=TIME+604848.0D0
      THETA=THETA*0.0174532925199D0
      LAMDA=LAMDA*0.0174532925199D0
      CTHETA=COS(THETA)
      STHETA=SIN(THETA)
      HR=DMOD(TIME,24.0D0)
      T=(TT+12.0D0)/876600.0D0
      T2=T*T
      HS=4.881627982482D0+628.3319508731D0*T
      HS=HS+0.523598775578D-5*T2
      HS=DMOD(DMOD(HS,PI20)+PI20,PI20)
      PS=4.908229466993D0+T*0.0300052641669D0
      PS=PS+0.790246300201D-5*T2
      ES=0.01675104D0- 0.00004180D0*T-0.000000126D0*T2
      PSIG=0.2617993877971D0*(HR-12.0D0)+HS
      IF(LORDER.NE.0.AND.LORDER.NE.2)   GO TO 82
      LS=HS+2.0D0*ES*DSIN(HS-PS)+1.25D0*ES**2*DSIN(2.0D0*(HS-PS))
      CZ=0.397980654630D0*DSIN(LS)
      SZ=DSQRT(1.0D0-CZ**2)
      Z=DATAN2(SZ,CZ)
      X=0.5D0*(LS+Z-HALFPI)
      THFPSI=1.52386101015D0*(DSIN(X)/DCOS(X))
      PSIS=2.0D0*DATAN(THFPSI)
      PSIS=DMOD(PSIS+TWOPI,TWOPI)
      RBARR=1.D0+ES*DCOS(HS-PS)+ES**2*DCOS(2.D0*(HS-PS))
      LL=PSIS-PSIG
      SLL=SIN(LAMDA-LL)
      CLL=COS(LAMDA-LL)
      CALFA=CTHETA*CZ+STHETA*SZ*CLL
      XI=4.2635E-5*RBARR
      CC=2.120E14*XI
      KR(2)=CC*XI*XI
      KR(3)=KR(2)*XI
      KR(4)=KR(3)*XI
      MU=CALFA
      P(2)=0.5*(3.*MU*MU-1.)
      P(3)=0.5*MU*(5.*MU*MU-3.)
      P(4)=0.25*(7.*MU*P(3)-3.*P(2))
      PP(2)=3.*MU
      PP(3)=1.5*(5.*MU*MU-1.)
      PP(4)=0.25*(7.*(P(3)+MU*PP(3))-3.*PP(2))
      PPP(2)=3.
      PPP(3)=15.*MU
      PPP(4)=7.5*(7.*MU*MU-1.)
      MUT=-STHETA*CZ+CTHETA*SZ*CLL
      MUTT=-MU
      MUL=-STHETA*SZ*SLL
      MULL=-STHETA*SZ*CLL
      MUTL=-CTHETA*SZ*SLL
      J=2
      GO TO(50,60,70),OPT
 50   GTSUN=0.
      DEL=1.+2.*H(J-1)/J-(J+1)*K(J-1)/J
      GTSUN=GTSUN+DEL*J*KR(J)*P(J)*G/RE
      GO TO 80
 60   TTSUN=0.
      DIM=1.+K(J-1)-H(J-1)
      TTSUN=TTSUN+(DIM*KR(J)*PP(J)/RE)*(MUT*SAZT+MUL*CAZT/STHETA)
      GO TO 80
 70    ELL=0.
      ETL=0.
      ETT=0.
      M=J-1
      ELL=ELL+KR(J)*(L(M)*(PP(J)*MUT*CTHETA/STHETA+(PPP(J)*
     1MUL*MUL+PP(J)*MULL)/(STHETA*STHETA))+H(M)*P(J))
      ETT=ETT+KR(J)*(L(M)*(PPP(J)*MUT*MUT+PP(J)*MUTT)+
     1  H(M)*P(J))
      ETL=ETL+2.*(KR(J)*L(M)*(PPP(J)*MUL*MUT+PP(J)*MUTL-
     1  CTHETA*PP(J)*MUL/STHETA))/STHETA
      STNSUN=(ELL*SAZS*SAZS+ETL*SAZS*CAZS+ETT*CAZS*CAZS)/RE
 80   CONTINUE
 82   HM=4.720008893870D0+8399.709274530D0*T
      HM=HM+0.345575191895D-4*T2
      HM=DMOD(DMOD(HM,PI20)+PI20,PI20)
      PM=5.835152597865D0+71.01804120839D0*T
      PM=PM-0.180108282526D-3*T2
      NM=4.523601611611D0-33.75714629423D0*T
      NM=NM+0.362640633469D-4*T2
      CNM=DCOS(NM)
      SNM=DSIN(NM)
      CW=0.91369D0-0.03569D0*CNM
      SW=DSQRT(1.0D0-CW**2)
      SNU=0.08968D0*SNM/SW
      CNU=DSQRT(1.0D0-SNU**2)
      NU=DATAN(SNU/CNU)
      SAW=0.39798D0*SNM/SW
      CAW=CNM*CNU+0.91739D0*SNM*SNU
      AW=2.0D0*DATAN(SAW/(1.0D0+CAW))
      AW=DMOD(AW+TWOPI,TWOPI)
      SIG=HM-NM+AW
      LM=SIG+0.109801D0*DSIN(HM-PM)+0.003768D0*DSIN(2.0D0*(HM-PM))
     1 -0.224412D0*ES*DSIN(HS-PS)+0.02045D0*DSIN(HM-2.0D0*HS+PM)
     2 +0.010809D0*DSIN(2.0D0*(HM-HS))+0.000653D0*DSIN(3.0D0*HM-2.0D0*HS
     3  -PM) +0.000451D0*DSIN(2.0D0*HM-3.0D0*HS+PS)
      CZ=DSIN(LM)*SW
      WM=DATAN2(SW,CW)
      SZ=DSQRT(1.0D0-CZ**2)
      ZM=DATAN2(SZ,CZ)
      X=0.5D0*(LM+ZM-HALFPI)
      TANP=(DSIN(X)/DCOS(X))*DSIN(0.5D0*(HALFPI+WM))/DSIN(0.5D0*(HALFPI-
     1  WM))
      PSIM=2.0D0*DATAN(TANP)
      PSIM=DMOD(PSIM+TWOPI,TWOPI)
      RBARR=1.0D0+0.05467D0*DCOS(HM-PM)+0.003011D0*DCOS(2.0D0*(HM-PM))
     1 -0.000141D0*DCOS(HS-PS)+0.009271D0*DCOS(HM-2.0D0*HS+PM)
     2+0.007759D0*DCOS(2.0D0*(HM-HS))+0.000633D0*DCOS(3.D0*HM-2.D0*HS-PM
     3) +0.000328D0*DCOS(2.D0*HM-3.D0*HS+PS)
      LL=NU+PSIM-PSIG
      SLL=SIN(LAMDA-LL)
      CLL=COS(LAMDA-LL)
      CALFA=CTHETA*CZ+STHETA*SZ*CLL
      XI=1.65933E-2*RBARR
      CC=7.834E6*XI
      KR(2)=CC*XI*XI
      J=3
      KR(J)=KR(J-1)*XI
      MU=CALFA
      P(1)=MU
      P(2)=0.5*(3.*MU*MU-1.)
      J=2
      P(J+1)=((2*J+1)*MU*P(J)-J*P(J-1))/(J+1)
      PP(1)=1.
      PP(2)=3*MU
      PPP(1)=0.
      PPP(2)=3.
      J=2
      PP(J+1)=((2*J+1)*(P(J)+MU*PP(J))-J*PP(J-1))/(J+1)
      PPP(J+1)=((2*J+1)*(2*PP(J)+MU*PPP(J))-J*PPP(J-1))/(J+1)
      MUT=-STHETA*CZ+CTHETA*SZ*CLL
      MUTT=-MU
      MUL=-STHETA*SZ*SLL
      MULL=-STHETA*SZ*CLL
      MUTL=-CTHETA*SZ*SLL
      GO TO (100,110,120),OPT
 100   GTMUN=0.
      DO  105  J=JS,JE
      DEL=1.+2*H(J-1)/J-(J+1)*K(J-1)/J
 105  GTMUN=GTMUN+DEL*J*KR(J)*P(J)*G/RE
      GO TO 130
 110   TTMUN=0.
      DO  115  J=JS,JE
      DIM=1.+K(J-1)-H(J-1)
 115  TTMUN=TTMUN+(DIM*KR(J)*PP(J)/RE)*(MUT*SAZT+MUL*CAZT/STHETA)
      GO TO 130
 120  ELL=0.
      ETL=0.
      ETT=0.
      DO 125 J=JS,JE
      M=J-1
      ELL=ELL+KR(J)*(L(M)*(PP(J)*MUT*CTHETA/STHETA+(PPP(J)*
     1  MUL*MUL+PP(J)*MULL)/(STHETA*STHETA))+H(M)*P(J))
      ETT=ETT+KR(J)*(L(M)*(PPP(J)*MUT*MUT+PP(J)*MUTT)+H(M)*P(J))
      ETL=ETL+2*(KR(J)*L(M)*(PPP(J)*MUL*MUT+PP(J)*MUTL-
     1 CTHETA*PP(J)*MUL/STHETA))/STHETA
 125  STNMUN=(ELL*SAZS*SAZS+ETL*SAZS*CAZS+ETT*CAZS*CAZS)/RE
 130  CONTINUE
      GO TO (140,150,160),OPT
140   RESULT=(GTSUN+GTMUN)*SCALE
      GO TO 170
150   RESULT=(TTSUN+TTMUN)*SCALE
      GO TO 170
160   RESULT=(STNSUN+STNMUN)*SCALE
170   CONTINUE
 180  CONTINUE
      RETURN
      END
c
c----------------------------------------------------------------------
c
        Double Precision Function TIM69(myr,mon,mday)
c  function to return the number of days from the beginning of 1969
c  to a given later date.
c  intended to be used to find the input variable for the program TIDEPT
c  and its relatives,which need time in hours from January 1,1969 0.0 hours
c  G.M.T.
c  this version goes wrong after 2100 and before 1800
c
      double precision st69,hours
      dimension iam(12)
      data iam/0,31,59,90,120,151,181,212,243,273,304,334/
      lday=mday-1
      kyr=myr-1969
      lyr=kyr
      if(lyr.lt.0)  lyr=lyr-3
      st69=kyr*365+iam(mon)+lday+lyr/4
      if(myr.eq.myr/4*4.and.mon.gt.2) st69=st69+1.0d0
      if(myr.le.1900.and.mon.le.2)  st69=st69+1.0d0
      hours = st69*24.00d0
      tim69=hours
      return
      end
c
c======================================================================
c
c text in subroutine is from file <gez.txt>
c
      subroutine gez_copyright
c
      print *,'Copyright (c) 1969 by R.A. Broucke, P. Muller '
     &       ,'(JPL)'
      print *,'Copyright (c) 1971 by R.A. Broucke, W. Zuern, '
     &       ,'L.B. Slichter'
      print *,' '
      print *,'Rigid earth gravity tides based on Brouckes '
     &       ,'code'
      print *,' '
      print *,'This program calculates tidal acceleration as '
     &       ,'would be observed on a'
      print *,'spherically symmetric rigid earth. The '
     &       ,'calculation is based on'
      print *,'ephemerides calculated in subroutines from '
     &       ,'JPL (Roger Broucke). The'
      print *,'Moon`s ephemeris is based on Brown`s theory, '
     &       ,'the Sun`s ephemeris is'
      print *,'based on Newcomb`s theory.'
      print *,' '
      print *,'See:'
      print *,'R.A. Broucke, W.E. Zuern, L.B. Slichter, '
     &       ,'1972. Lunar Tidal'
      print *,'Acceleration on a Ridig Earth. Geophysical '
     &       ,'Monograph Series, Vol. 16.'
      print *,'319 - 324. American Geophysical Union, '
     &       ,'Washington, D.C.'
c
      return
      end
c
c======================================================================
c
c text in subroutine is from file <bfotide.txt>
c
      subroutine bfotide_copyright
c
      print *,'Copyright (c) 1959 by Jon Berger, Russ Evans, '
     &       ,'and Dan McKenzie'
      print *,'Copyright (c) 1974 by Walter Zuern'
      print *,'Copyright (c) 1978 by David Young'
      print *,' '
      print *,'Earth response to tidal forces based on '
     &       ,'Longmans code'
      print *,' '
      print *,'This program calculates the response of an '
     &       ,'elastic earth to tidal'
      print *,'forces. The Earth`s elasticity is defined by '
     &       ,'Love-numbers in'
      print *,'subroutine TIDEPT. The program computes '
     &       ,'acceleration, strain and tilt.'
      print *,'The calculation is based on ephemerides based '
     &       ,'on Longman`s theory.'
      print *,' '
      print *,'See:'
      print *,'I.M. Longman, 1959. Formulas for Computing '
     &       ,'the Tidal Accelerations due'
      print *,'to the Moon and the Sun. Journal of '
     &       ,'Geophysical Research, Vol. 64, No.'
      print *,'12, 2351 - 2355.'
c
      return
      end
c
c ----- END OF tidesff.f ----- 
