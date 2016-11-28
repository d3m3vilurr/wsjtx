program msk144sim

  use wavhdr
  parameter (NMAX=15*12000)
  real pings(0:NMAX-1)
  real waveform(0:NMAX-1)
  character*6 mygrid
  character arg*8,msg*22,msgsent*22,fname*40
  real wave(0:NMAX-1)              !Simulated received waveform
  real*8 twopi,freq,phi,dphi0,dphi1,dphi
  type(hdr) h                          !Header for .wav file
  integer*2 iwave(0:NMAX-1)
  integer itone(144)                   !Message bits
  integer*1 bcontest
  data mygrid/"EN50wc"/
  data bcontest/0/

  nargs=iargc()
  if(nargs.ne.5) then
     print*,'Usage:    msk144sim        message       freq width snr nfiles'
     print*,' '
     print*,'Example: msk144sim  "K1ABC W9XYZ EN37"  1500  0.12  2   1'
     go to 999
  endif
  call getarg(1,msg)
  call getarg(2,arg)
  read(arg,*) freq
  call getarg(3,arg)
  read(arg,*) width
  call getarg(4,arg)
  read(arg,*) snrdb
  call getarg(5,arg)
  read(arg,*) nfiles

!sig is the peak amplitude of the ping. 
  sig=sqrt(2.0)*10.0**(0.05*snrdb)
  h=default_header(12000,NMAX)

  ichk=0
  call genmsk144(msg,mygrid,ichk,bcontest,msgsent,itone,itype) 
  twopi=8.d0*atan(1.d0)

  nsym=144
  if( itone(41) .lt. 0 ) nsym=40
  dphi0=twopi*(freq-500)/12000.0
  dphi1=twopi*(freq+500)/12000.0
  phi=0.0
  indx=0
  nreps=NMAX/(nsym*6)
  do jrep=1,nreps
    do i=1,nsym
      if( itone(i) .eq. 0 ) then
        dphi=dphi0
      else
        dphi=dphi1
      endif
      do j=1,6  
        waveform(indx)=cos(phi);
        indx=indx+1
        phi=mod(phi+dphi,twopi)
      enddo 
    enddo
  enddo 

  if(itype.lt.1 .or. itype.gt.7) then
     print*,'Illegal message'
     go to 999
  endif

  call makepings(pings,NMAX,width,sig)

!  call sgran()
  do ifile=1,nfiles                  !Loop over requested number of files
     write(fname,1002) ifile         !Output filename
1002 format('000000_',i6.6)
     open(10,file=fname(1:13)//'.wav',access='stream',status='unknown')

     wave=0.0
     iwave=0
     fac=sqrt(6000.0/2500.0)
     do i=0,NMAX-1
        xx=gran()
        wave(i)=pings(i)*waveform(i) + fac*xx
!        wave(i)=sig*waveform(i) + fac*xx
        iwave(i)=30.0*wave(i)
     enddo

     write(10) h,iwave               !Save the .wav file
     close(10)

  enddo

999 end program msk144sim