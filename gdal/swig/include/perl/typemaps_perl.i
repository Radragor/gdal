/*
 * Perl typemaps for GDAL SWIG bindings
 * Copyright Ari Jolma 2005.  Based on typemaps_python.i
 * You may distribute this file under the same terms as GDAL itself.
 */

/*
 * Include the typemaps from swig library for returning of
 * standard types through arguments.
 */
%include "typemaps.i"

%typemap(in) GIntBig
{
    $1 = CPLAtoGIntBig(SvPV_nolen($input));
}

%typemap(out) GIntBig
{
    char temp[256];
    sprintf(temp, "" CPL_FRMT_GIB "", $1);
    $result = sv_2mortal(newSVpv(temp, 0));
    argvi++;
}

%typemap(in) GUIntBig
{
    $1 = CPLScanUIntBig(SvPV_nolen($input), 30);
}

%typemap(out) GUIntBig
{
    char temp[256];
    sprintf(temp, "" CPL_FRMT_GUIB "", $1);
    $result = sv_2mortal(newSVpv(temp, 0));
    argvi++;
}

%apply (long *OUTPUT) { long *argout };
%apply (double *OUTPUT) { double *argout };
%apply (double *OUTPUT) { double *defaultval };

%fragment("sv_to_utf8_string", "header") %{
    char *sv_to_utf8_string(SV *sv, U8 **tmpbuf) {
        /* if tmpbuf, only tmpbuf is freed; if not, ret is freed*/
        char *ret;
        if (SvOK(sv)) {
            STRLEN len;
            ret = SvPV(sv, len);
            if (!SvUTF8(sv)) {
                if (tmpbuf) {
                    *tmpbuf = bytes_to_utf8((const U8*)ret, &len);
                    ret = (char *)(*tmpbuf);
                } else {
                    ret = (char *)bytes_to_utf8((const U8*)ret, &len);
                }
            } else {
                if (!tmpbuf)
                    ret = strdup(ret);
            }
        } else {
            ret = (char*)""; /* avoid "Use of uninitialized value in subroutine entry" errors */
            if (!tmpbuf)
                ret = strdup(ret);
        }
        return ret;
    }
    %}

/*
 * double *val, int*hasval, is a special contrived typemap used for
 * the RasterBand GetNoDataValue, GetMinimum, GetMaximum, GetOffset,
 * GetScale methods. The variable hasval is tested and if it is false
 * (meaning, the value is not set in the raster band) then undef is
 * returned in scalar context.  If it is != 0, then the value is
 * coerced into a long and returned in scalar context. In list context
 * the value and hasval are returned. If hasval is zero, the value is
 * "generally the minimum supported value for the data type".
 */

%typemap(in,numinputs=0) (double *val, int *hasval) ( double tmpval, int tmphasval ) {
    /* %typemap(in,numinputs=0) (double *val, int *hasval) */
    $1 = &tmpval;
    $2 = &tmphasval;
 }
%typemap(argout) (double *val, int *hasval) {
    /* %typemap(argout) (double *val, int *hasval) */
    if (GIMME_V == G_ARRAY) {
        EXTEND(SP, argvi+2-items+1);
        $result = sv_newmortal();
        sv_setnv($result, *$1);
        argvi++;
        $result = sv_newmortal();
        sv_setiv($result, *$2);
        argvi++;
    } else {
        if ( *$2 ) {
            $result = sv_newmortal();
            sv_setnv($result, *$1);
            argvi++;
        }
    }
}

%typemap(out) const char *
{
    /* %typemap(out) const char * */
    $result = newSVpv(result, 0);
    SvUTF8_on($result); /* expecting GDAL to give us UTF-8 */
    sv_2mortal($result);
    argvi++;
}
%typemap(out) (char **CSL)
{
    /* %typemap(out) char **CSL */
    if (GIMME_V == G_ARRAY) {
        if ($1) {
            int n = CSLCount($1);
            EXTEND(SP, argvi+n-items+1);
            int i;
            for (i = 0; $1[i]; i++) {
                SV *sv = newSVpv($1[i], 0);
                SvUTF8_on(sv); /* expecting GDAL to give us UTF-8 */
                ST(argvi++) = sv_2mortal(sv);
            }
            CSLDestroy($1);
        }
    } else {
        AV *av = (AV*)sv_2mortal((SV*)newAV());
        if ($1) {
            int i;
            for (i = 0; $1[i]; i++) {
                SV *sv = newSVpv($1[i], 0);
                SvUTF8_on(sv); /* expecting GDAL to give us UTF-8 */
                av_push(av, sv);
            }
            CSLDestroy($1);
        }
        $result = newRV((SV*)av);
        sv_2mortal($result);
        argvi++;
    }
}
%typemap(out) (char **CSL_REF)
{
    /* %typemap(out) char **CSL_REF */
    AV *av = (AV*)sv_2mortal((SV*)newAV());
    if ($1) {
        int i;
        for (i = 0; $1[i]; i++) {
            SV *sv = newSVpv($1[i], 0);
            SvUTF8_on(sv); /* expecting GDAL to give us UTF-8 */
            av_push(av, sv);
        }
        CSLDestroy($1);
    }
    $result = newRV((SV*)av);
    sv_2mortal($result);
    argvi++;
}
%typemap(out) (char **free)
{
    /* %typemap(out) char **free */
    AV *av = (AV*)sv_2mortal((SV*)newAV());
    if ($1) {
        int i;
        for (i = 0; $1[i]; i++) {
            av_store(av, i, newSVpv($1[0], 0));
        }
        CPLFree($1);
    }
    $result = newRV((SV*)av);
    sv_2mortal($result);
    argvi++;
}

/* typemaps for VSI_RETVAL */

/* drop GDAL return value */
%typemap(out) VSI_RETVAL
{
    /* %typemap(out) VSI_RETVAL */
}
/* croak if GDAL returns -1 */
%typemap(ret) VSI_RETVAL
{
    /* %typemap(ret) VSI_RETVAL */
    if ($1 == -1 ) {
        do_confess(strerror(errno), 1);
    }
}

/* typemaps for IF_FALSE_RETURN_NONE */

/* drop GDAL return value */
%typemap(out) IF_FALSE_RETURN_NONE
{
    /* %typemap(out) IF_FALSE_RETURN_NONE */
}
/* croak if GDAL return FALSE */
%typemap(ret) IF_FALSE_RETURN_NONE
{
    /* %typemap(ret) IF_FALSE_RETURN_NONE */
    if ($1 == 0 ) {
        do_confess(CALL_FAILED, 1);
    }
}
/* drop GDAL return value */
%typemap(out) IF_ERROR_RETURN_NONE
{
    /* %typemap(out) IF_ERROR_RETURN_NONE */
}
%typemap(out) CPLErr
{
    /* %typemap(out) CPLErr */
}
/* return value is really void or prepared by typemaps, avoids unnecessary sv_newmortal */
%typemap(out) void
{
    /* %typemap(out) void */
}

/*
 * SWIG macro to define fixed length array typemaps
 * defines three different typemaps.
 *
 * 1) For argument in.  The wrapped function's prototype is:
 *
 *    FunctionOfDouble3( double *vector );
 *
 *    The function assumes that vector points to three consecutive doubles.
 *    This can be wrapped using:
 *
 *    %apply (double_3 argin) { (double *vector) };
 *    FunctionOfDouble3( double *vector );
 *    %clear (double *vector);
 *
 *    Example:  Dataset.SetGeoTransform().
 *
 * 2) Functions which modify a fixed length array passed as
 *    an argument or return data in an array allocated by the
 *    caller.
 *
 *    %apply (double_6 argout ) { (double *vector) };
 *    GetVector6( double *vector );
 *    %clear ( double *vector );
 *
 *    Example:  Dataset.GetGeoTransform().
 *
 * 3) Functions which take a double **.  Through this argument it
 *    returns a pointer to a fixed size array allocated with CPLMalloc.
 *
 *    %apply (double_17 *argoug) { (double **vector) };
 *    ReturnVector17( double **vector );
 *    %clear ( double **vector );
 *
 *    Example:  SpatialReference.ExportToPCI().
 *
 */

%fragment("CreateArrayFromIntArray","header") %{
    static SV *
        CreateArrayFromIntArray( int *first, unsigned int size ) {
        AV *av = (AV*)sv_2mortal((SV*)newAV());
        for( unsigned int i=0; i<size; i++ ) {
            av_store(av,i,newSViv(*first));
            ++first;
        }
        return sv_2mortal(newRV((SV*)av));
    }
    %}

%fragment("CreateArrayFromGIntBigArray","header") %{
#define LENGTH_OF_GIntBig_AS_STRING 30
    static SV *
        CreateArrayFromGIntBigArray( GIntBig *first, unsigned int size ) {
        AV *av = (AV*)sv_2mortal((SV*)newAV());
        for( unsigned int i=0; i<size; i++ ) {
            char s[LENGTH_OF_GIntBig_AS_STRING];
            snprintf(s, LENGTH_OF_GIntBig_AS_STRING-1, CPL_FRMT_GIB, *first);
            av_store(av,i,newSVpv(s, 0));
            ++first;
        }
        return sv_2mortal(newRV((SV*)av));
    }
    %}

%fragment("CreateArrayFromGUIntBigArray","header") %{
#define LENGTH_OF_GUIntBig_AS_STRING 30
    static SV *
        CreateArrayFromGUIntBigArray( GUIntBig *first, unsigned int size ) {
        AV *av = (AV*)sv_2mortal((SV*)newAV());
        for( unsigned int i=0; i<size; i++ ) {
            char s[LENGTH_OF_GUIntBig_AS_STRING];
            snprintf(s, LENGTH_OF_GUIntBig_AS_STRING-1, CPL_FRMT_GUIB, *first);
            av_store(av,i,newSVpv(s, 0));
            ++first;
        }
        return sv_2mortal(newRV((SV*)av));
    }
    %}

%fragment("CreateArrayFromDoubleArray","header") %{
    static SV *
        CreateArrayFromDoubleArray( double *first, unsigned int size ) {
        AV *av = (AV*)sv_2mortal((SV*)newAV());
        for( unsigned int i=0; i<size; i++ ) {
            av_store(av,i,newSVnv(*first));
            ++first;
        }
        return sv_2mortal(newRV((SV*)av));
    }
    %}

%fragment("CreateArrayFromStringArray","header") %{
    static SV *
        CreateArrayFromStringArray( char **first ) {
        AV *av = (AV*)sv_2mortal((SV*)newAV());
        for( unsigned int i = 0; *first != NULL; i++ ) {
            SV *sv = newSVpv(*first, strlen(*first));
            SvUTF8_on(sv); /* expecting UTF-8 from GDAL */
            av_store(av,i,sv);
            ++first;
        }
        return sv_2mortal(newRV((SV*)av));
    }
    %}

/* typemaps for (int *nLen, const int **pList) */

%typemap(in,numinputs=0) (int *nLen, const int **pList) (int nLen, int *pList)
{
    /* %typemap(in,numinputs=0) (int *nLen, const int **pList) */
    $1 = &nLen;
    $2 = &pList;
}
%typemap(argout,fragment="CreateArrayFromIntArray") (int *nLen, const int **pList)
{
    /* %typemap(argout) (int *nLen, const int **pList) */
    $result = CreateArrayFromIntArray( *($2), *($1) );
    argvi++;
}

/* typemaps for (int *nLen, const GIntBig **pList) */

%typemap(in,numinputs=0) (int *nLen, const GIntBig **pList) (int nLen, GIntBig *pList)
{
    /* %typemap(in,numinputs=0) (int *nLen, const GIntBig **pList) */
    $1 = &nLen;
    $2 = &pList;
}
%typemap(argout,fragment="CreateArrayFromGIntBigArray") (int *nLen, const GIntBig **pList)
{
    /* %typemap(argout) (int *nLen, const GIntBig **pList) */
    $result = CreateArrayFromGIntBigArray( *($2), *($1) );
    argvi++;
}

/* typemaps for (int *nLen, const GUIntBig **pList) */

%typemap(in,numinputs=0) (int *nLen, const GUIntBig **pList) (int nLen, GUIntBig *pList)
{
    /* %typemap(in,numinputs=0) (int *nLen, const GUIntBig **pList) */
    $1 = &nLen;
    $2 = &pList;
}
%typemap(argout,fragment="CreateArrayFromGUIntBigArray") (int *nLen, const GUIntBig **pList)
{
    /* %typemap(argout) (int *nLen, const GUIntBig **pList) */
    $result = CreateArrayFromGUIntBigArray( *($2), *($1) );
    argvi++;
}

/* typemaps for (int len, int *output) */

%typemap(in,numinputs=1) (int len, int *output)
{
    /* %typemap(in,numinputs=1) (int len, int *output) */
    $1 = SvIV($input);
}
%typemap(check) (int len, int *output)
{
    /* %typemap(check) (int len, int *output) */
    if ($1 < 1) $1 = 1; /* stop idiocy */
    $2 = (int *)CPLMalloc( $1 * sizeof(int) );

}
%typemap(argout,fragment="CreateArrayFromIntArray") (int len, int *output)
{
    /* %typemap(argout) (int len, int *output) */
    if (GIMME_V == G_ARRAY) {
        /* return a list */
        int i;
        EXTEND(SP, argvi+$1-items+1);
        for (i = 0; i < $1; i++)
            ST(argvi++) = sv_2mortal(newSViv($2[i]));
    } else {
        $result = CreateArrayFromIntArray( $2, $1 );
        argvi++;
    }
}
%typemap(freearg) (int len, int *output)
{
    /* %typemap(freearg) (int len, int *output) */
    CPLFree($2);
}

/* typemaps for (int len, GUIntBig *output) */

%typemap(in,numinputs=1) (int len, GUIntBig *output)
{
    /* %typemap(in,numinputs=1) (int len, GUIntBig *output) */
    $1 = SvIV($input);
}
%typemap(check) (int len, GUIntBig *output)
{
    /* %typemap(check) (int len, GUIntBig *output) */
    if ($1 < 1) $1 = 1; /* stop idiocy */
    $2 = (GUIntBig*)CPLMalloc( $1 * sizeof(GUIntBig) );

}
%typemap(argout,fragment="CreateArrayFromGUIntBigArray") (int len, GUIntBig *output)
{
    /* %typemap(argout) (int len, GUIntBig *output) */
    if (GIMME_V == G_ARRAY) {
        /* return a list */
        int i;
        EXTEND(SP, argvi+$1-items+1);
        for (i = 0; i < $1; i++) {
            char s[LENGTH_OF_GUIntBig_AS_STRING];
            snprintf(s, LENGTH_OF_GUIntBig_AS_STRING-1, CPL_FRMT_GUIB, $2[i]);
            ST(argvi++) = sv_2mortal(newSVpv(s, 0));
        }
    } else {
        $result = CreateArrayFromGUIntBigArray( $2, $1 );
        argvi++;
    }
}
%typemap(freearg) (int len, GUIntBig *output)
{
    /* %typemap(freearg) (int len, GUIntBig *output) */
    CPLFree($2);
}

/* typemaps for (int nLen, double *pList) */

%typemap(in,numinputs=0) (int *nLen, const double **pList) (int nLen, double *pList)
{
    /* %typemap(in,numinputs=0) (int *nLen, const double **pList) */
    $1 = &nLen;
    $2 = &pList;
}
%typemap(argout,fragment="CreateArrayFromDoubleArray") (int *nLen, const double **pList)
{
    /* %typemap(argout) (int *nLen, const double **pList) */
    $result = CreateArrayFromDoubleArray( *($2), *($1) );
    argvi++;
}

%typemap(in,numinputs=0) (char ***pList) (char **pList)
{
    /* %typemap(in,numinputs=0) (char ***pList) */
    $1 = &pList;
}
%typemap(argout,fragment="CreateArrayFromStringArray") (char ***pList)
{
    /* %typemap(argout) (char ***pList) */
    $result = CreateArrayFromStringArray( *($1) );
    argvi++;
}

%typemap(in,numinputs=0) ( double argout[ANY]) (double argout[$dim0])
{
    /* %typemap(in,numinputs=0) (double argout[ANY]) */
    $1 = argout;
}
%typemap(argout,fragment="CreateArrayFromDoubleArray") ( double argout[ANY])
{
    /* %typemap(argout) (double argout[ANY]) */
    if (GIMME_V == G_ARRAY) {
        /* return a list */
        int i;
        EXTEND(SP, argvi+$dim0-items+1);
        for (i = 0; i < $dim0; i++)
            ST(argvi++) = sv_2mortal(newSVnv($1[i]));
    } else {
        $result = CreateArrayFromDoubleArray( $1, $dim0 );
        argvi++;
    }
}

%typemap(in,numinputs=0) ( double *argout[ANY]) (double *argout)
{
    /* %typemap(in,numinputs=0) (double *argout[ANY]) */
    $1 = &argout;
}
%typemap(argout,fragment="CreateArrayFromDoubleArray") ( double *argout[ANY])
{
    /* %typemap(argout) (double *argout[ANY]) */
    $result = CreateArrayFromDoubleArray( *$1, $dim0 );
    argvi++;
}
%typemap(freearg) (double *argout[ANY])
{
    /* %typemap(freearg) (double *argout[ANY]) */
    CPLFree(*$1);
}
%typemap(in) (double argin[ANY]) (double argin[$dim0])
{
    /* %typemap(in) (double argin[ANY]) */
    if (!(SvROK($input) && (SvTYPE(SvRV($input))==SVt_PVAV)))
        do_confess(NEED_ARRAY_REF, 1);
    $1 = argin;
    AV *av = (AV*)(SvRV($input));
    if (av_len(av)+1 < $dim0)
      do_confess(NOT_ENOUGH_ELEMENTS, 1);
    for (unsigned int i=0; i<$dim0; i++) {
        SV *sv = *av_fetch(av, i, 0);
        if (!SvOK(sv))
            do_confess(NEED_DEF, 1);
        $1[i] =  SvNV(sv);
    }
}

/* typemaps for (int nList, int* pList) */

%typemap(typecheck, precedence=SWIG_TYPECHECK_INTEGER) int nList, int* pList {
    /* %typemap(typecheck, precedence=SWIG_TYPECHECK_INTEGER) int nList, int* pList */
   $1 = 1;
}
%typemap(in,numinputs=1) (int nList, int* pList)
{
    /* %typemap(in,numinputs=1) (int nList, int* pList) */
    if (!(SvROK($input) && (SvTYPE(SvRV($input))==SVt_PVAV)))
        do_confess(NEED_ARRAY_REF, 1);
    AV *av = (AV*)(SvRV($input));
    $1 = av_len(av)+1;
    $2 = (int*)CPLMalloc($1*sizeof(int));
    if ($2) {
        for( int i = 0; i<$1; i++ ) {
            SV **sv = av_fetch(av, i, 0);
            $2[i] =  SvIV(*sv);
        }
    } else
        SWIG_fail;
}
%typemap(freearg) (int nList, int* pList)
{
    /* %typemap(freearg) (int nList, int* pList) */
    CPLFree((void*) $2);
}

/* typemaps for (int nList, GIntBig* pList) */

%typemap(typecheck, precedence=SWIG_TYPECHECK_INTEGER) int nList, GIntBig* pList {
    /* %typemap(typecheck, precedence=SWIG_TYPECHECK_INTEGER) int nList, GIntBig* pList */
   $1 = 1;
}
%typemap(in,numinputs=1) (int nList, GIntBig* pList)
{
    /* %typemap(in,numinputs=1) (int nList, GIntBig* pList) */
    if (!(SvROK($input) && (SvTYPE(SvRV($input))==SVt_PVAV)))
        do_confess(NEED_ARRAY_REF, 1);
    AV *av = (AV*)(SvRV($input));
    $1 = av_len(av)+1;
    $2 = (GIntBig*)CPLMalloc($1*sizeof(GIntBig));
    if ($2) {
        for( int i = 0; i<$1; i++ ) {
            SV **sv = av_fetch(av, i, 0);
            $2[i] =  CPLAtoGIntBig(SvPV_nolen(*sv));
        }
    } else
        SWIG_fail;
}
%typemap(freearg) (int nList, GIntBig* pList)
{
    /* %typemap(freearg) (int nList, GIntBig* pList) */
    CPLFree((void*) $2);
}

/* typemaps for (int nList, GUIntBig* pList) */

%typemap(typecheck, precedence=SWIG_TYPECHECK_INTEGER) int nList, GUIntBig* pList {
    /* %typemap(typecheck, precedence=SWIG_TYPECHECK_INTEGER) int nList, GUIntBig* pList */
   $1 = 1;
}
%typemap(in,numinputs=1) (int nList, GUIntBig* pList)
{
    /* %typemap(in,numinputs=1) (int nList, GUIntBig* pList) */
    if (!(SvROK($input) && (SvTYPE(SvRV($input))==SVt_PVAV)))
        do_confess(NEED_ARRAY_REF, 1);
    AV *av = (AV*)(SvRV($input));
    $1 = av_len(av)+1;
    $2 = (GUIntBig*)CPLMalloc($1*sizeof(GUIntBig));
    if ($2) {
        for( int i = 0; i<$1; i++ ) {
            SV **sv = av_fetch(av, i, 0);
            $2[i] =  CPLScanUIntBig(SvPV_nolen(*sv), 30);
        }
    } else
        SWIG_fail;
}
%typemap(freearg) (int nList, GUIntBig* pList)
{
    /* %typemap(freearg) (int nList, GUIntBig* pList) */
    CPLFree((void*) $2);
}

/* typemaps for (int nList, double* pList) */

%typemap(in,numinputs=1) (int nList, double* pList)
{
    /* %typemap(in,numinputs=1) (int nList, double* pList) */
    if (!(SvROK($input) && (SvTYPE(SvRV($input))==SVt_PVAV)))
        do_confess(NEED_ARRAY_REF, 1);
    AV *av = (AV*)(SvRV($input));
    $1 = av_len(av)+1;
    $2 = (double*)CPLMalloc($1*sizeof(double));
    if ($2) {
        for( int i = 0; i<$1; i++ ) {
            SV **sv = av_fetch(av, i, 0);
            $2[i] =  SvNV(*sv);
        }
    } else
        SWIG_fail;
}
%typemap(freearg) (int nList, double* pList)
{
    /* %typemap(freearg) (int nList, double* pList) */
    CPLFree((void*) $2);
}

%typemap(in,numinputs=1) (int defined, double value)
{
    /* %typemap(in,numinputs=1) (int defined, double value) */
    $1 = SvOK($input);
    $2 = SvNV($input);
}

/*
 * Typemap for buffers with length <-> AV
 * Used in Band::ReadRaster() and Band::WriteRaster()
 *
 * This typemap has a typecheck also since the WriteRaster()
 * methods are overloaded.
 */
%typemap(in,numinputs=0) (int *nLen, char **pBuf ) ( int nLen = 0, char *pBuf = 0 )
{
    /* %typemap(in,numinputs=0) (int *nLen, char **pBuf ) */
    $1 = &nLen;
    $2 = &pBuf;
}
%typemap(argout) (int *nLen, char **pBuf )
{
    /* %typemap(argout) (int *nLen, char **pBuf ) */
    $result = sv_2mortal(newSVpv( *$2, *$1 ));
    argvi++;
}
%typemap(freearg) (int *nLen, char **pBuf )
{
    /* %typemap(freearg) (int *nLen, char **pBuf ) */
    if( *$1 ) {
        free( *$2 );
    }
}
%typemap(in,numinputs=0) (GIntBig *nLen, char **pBuf ) ( GIntBig nLen = 0, char *pBuf = 0 )
{
    /* %typemap(in,numinputs=0) (GIntBig *nLen, char **pBuf ) */
    $1 = &nLen;
    $2 = &pBuf;
}
%typemap(argout) (GIntBig *nLen, char **pBuf )
{
    /* %typemap(argout) (GIntBig *nLen, char **pBuf ) */
    $result = sv_2mortal(newSVpv( *$2, *$1 ));
    argvi++;
}
%typemap(freearg) (GIntBig *nLen, char **pBuf )
{
    /* %typemap(freearg) (GIntBig *nLen, char **pBuf ) */
    if( *$1 ) {
        free( *$2 );
    }
}
%typemap(in,numinputs=1) (int nLen, char *pBuf )
{
    /* %typemap(in,numinputs=1) (int nLen, char *pBuf ) */
    if (SvOK($input)) {
        SV *sv = $input;
        if (SvROK(sv) && SvTYPE(SvRV(sv)) < SVt_PVAV)
            sv = SvRV(sv);
        if (!SvPOK(sv))
            do_confess(NEED_BINARY_DATA, 1);
        STRLEN len = SvCUR(sv);
        $2 = SvPV_nolen(sv);
        $1 = len;
    } else {
        $2 = NULL;
        $1 = 0;
    }
}
%typemap(in,numinputs=1) (int nLen, unsigned char *pBuf )
{
    /* %typemap(in,numinputs=1) (int nLen, unsigned char *pBuf ) */
    if (SvOK($input)) {
        SV *sv = $input;
        if (SvROK(sv) && SvTYPE(SvRV(sv)) < SVt_PVAV)
            sv = SvRV(sv);
        if (!SvPOK(sv))
            do_confess(NEED_BINARY_DATA, 1);
        STRLEN len = SvCUR(sv);
        $2 = (unsigned char *)SvPV_nolen(sv);
        $1 = len;
    } else {
        $2 = NULL;
        $1 = 0;
    }
}
%typemap(in,numinputs=1) (GIntBig nLen, char *pBuf )
{
    /* %typemap(in,numinputs=1) (GIntBig nLen, char *pBuf ) */
    if (SvOK($input)) {
        SV *sv = $input;
        if (SvROK(sv) && SvTYPE(SvRV(sv)) < SVt_PVAV)
            sv = SvRV(sv);
        if (!SvPOK(sv))
            do_confess(NEED_BINARY_DATA, 1);
        STRLEN len = SvCUR(sv);
        $2 = SvPV_nolen(sv);
        $1 = len;
    } else {
        $2 = NULL;
        $1 = 0;
    }
}

/***************************************************
 * Typemaps for  (retStringAndCPLFree*)
 ***************************************************/

%typemap(out) (retStringAndCPLFree*)
%{
    /* %typemap(out) (retStringAndCPLFree*) */
    if($1)
    {
        $result = SWIG_FromCharPtr((const char *)result);
        CPLFree($1);
    }
    else
    {
        $result = &PL_sv_undef;
    }
    argvi++ ;
    %}

/* slightly different version(?) for GDALAsyncReader */
%typemap(in,numinputs=0) (int *nLength, char **pBuffer ) ( int nLength = 0, char *pBuffer = 0 )
{
    /* %typemap(in,numinputs=0) (int *nLength, char **pBuffer ) */
    $1 = &nLength;
    $2 = &pBuffer;
}
%typemap(freearg) (int *nLength, char **pBuffer )
{
    /* %typemap(freearg) (int *nLength, char **pBuffer ) */
    if( *$1 ) {
        free( *$2 );
    }
}


/*
 * Typemap argout of GDAL_GCP* used in Dataset::GetGCPs( )
 */
%typemap(in,numinputs=0) (int *nGCPs, GDAL_GCP const **pGCPs ) (int nGCPs=0, GDAL_GCP *pGCPs=0 )
{
    /* %typemap(in,numinputs=0) (int *nGCPs, GDAL_GCP const **pGCPs ) */
    $1 = &nGCPs;
    $2 = &pGCPs;
}
%typemap(argout) (int *nGCPs, GDAL_GCP const **pGCPs )
{
    /* %typemap(argout) (int *nGCPs, GDAL_GCP const **pGCPs ) */
    AV *dict = (AV*)sv_2mortal((SV*)newAV());
    for( int i = 0; i < *$1; i++ ) {
        GDAL_GCP *o = new_GDAL_GCP( (*$2)[i].dfGCPX,
                                    (*$2)[i].dfGCPY,
                                    (*$2)[i].dfGCPZ,
                                    (*$2)[i].dfGCPPixel,
                                    (*$2)[i].dfGCPLine,
                                    (*$2)[i].pszInfo,
                                    (*$2)[i].pszId );
        SV *sv = newSV(0);
        SWIG_MakePtr( sv, (void*)o, $*2_descriptor, SWIG_SHADOW|SWIG_OWNER);
        av_store(dict, i, sv);
    }
    $result = sv_2mortal(newRV((SV*)dict));
    argvi++;
}
%typemap(in,numinputs=1) (int nGCPs, GDAL_GCP const *pGCPs )
{
    /* %typemap(in,numinputs=1) (int nGCPs, GDAL_GCP const *pGCPs ) */
    if (!(SvROK($input) && (SvTYPE(SvRV($input))==SVt_PVAV)))
        do_confess(NEED_ARRAY_REF, 1);
    AV *av = (AV*)(SvRV($input));
    $1 = av_len(av)+1;
    $2 = (GDAL_GCP *)CPLMalloc($1*sizeof(GDAL_GCP));
    if ($2) {
        for (int i = 0; i < $1; i++ ) {
            SV **sv = av_fetch(av, i, 0);
            GDAL_GCP *gcp;
            int ret = SWIG_ConvertPtr(*sv, (void**)&gcp, SWIGTYPE_p_GDAL_GCP, 0);
            if (!SWIG_IsOK(ret))
                do_confess(WRONG_ITEM_IN_ARRAY, 1);
            $2[i] = *gcp;
        }
    } else
        do_confess(OUT_OF_MEMORY, 1);
}
%typemap(freearg) (int nGCPs, GDAL_GCP const *pGCPs )
{
    /* %typemap(freearg) (int nGCPs, GDAL_GCP const *pGCPs ) */
    CPLFree($2);
}

/*
 * Typemap for GDALColorEntry* <-> AV
 * GDALColorEntry* may be a return value and both input and output param
 */
%typemap(out) GDALColorEntry*
{
    /* %typemap(out) GDALColorEntry* */
    if (!result)
        do_confess(CALL_FAILED, 1);
    $result = sv_newmortal();
    sv_setiv(ST(argvi++), (IV) result->c1);
    $result = sv_newmortal();
    sv_setiv(ST(argvi++), (IV) result->c2);
    $result = sv_newmortal();
    sv_setiv(ST(argvi++), (IV) result->c3);
    $result = sv_newmortal();
    sv_setiv(ST(argvi++), (IV) result->c4);
}
%typemap(in,numinputs=0) GDALColorEntry*(GDALColorEntry e)
{
    /* %typemap(in,numinputs=0) GDALColorEntry*(GDALColorEntry e) */
    $1 = &e;
}
%typemap(argout) GDALColorEntry*
{
    /* %typemap(argout) GDALColorEntry* */
    if (!result)
        do_confess(CALL_FAILED, 1);
    argvi--;
    $result = sv_newmortal();
    sv_setiv(ST(argvi++), (IV) e3.c1);
    $result = sv_newmortal();
    sv_setiv(ST(argvi++), (IV) e3.c2);
    $result = sv_newmortal();
    sv_setiv(ST(argvi++), (IV) e3.c3);
    $result = sv_newmortal();
    sv_setiv(ST(argvi++), (IV) e3.c4);
}
%typemap(argout) const GDALColorEntry*
{
    /* %typemap(argout) const GDALColorEntry* */
}
%typemap(in,numinputs=1) const GDALColorEntry*(GDALColorEntry e)
{
    /* %typemap(in,numinputs=1) const GDALColorEntry*(GDALColorEntry e) */
    $1 = &e3;
    int ok = SvROK($input) && SvTYPE(SvRV($input))==SVt_PVAV;
    AV *av;
    if (ok)
        av = (AV*)(SvRV($input));
    else
        do_confess(NEED_ARRAY_REF, 1);
    SV **sv = av_fetch(av, 0, 0);
    if (sv)
        $1->c1 = SvIV(*sv);
    else
        $1->c1 = 0;
    sv = av_fetch(av, 1, 0);
    if (sv)
        $1->c2 = SvIV(*sv);
    else
        $1->c2 = 0;
    sv = av_fetch(av, 2, 0);
    if (sv)
        $1->c3 = SvIV(*sv);
    else
        $1->c3 = 0;
    sv = av_fetch(av, 3, 0);
    if (sv)
        $1->c4 = SvIV(*sv);
    else
        $1->c4 = 255;
}

/*
 * Typemap char ** <-> HV *
 */
%typemap(typecheck,precedence=SWIG_TYPECHECK_POINTER) (char **dict)
{
    /* %typecheck(SWIG_TYPECHECK_POINTER) (char **dict) */
    $1 = (SvROK($input) && (SvTYPE(SvRV($input))==SVt_PVHV)) ? 1 : 0;
}
%typemap(in) char **dict
{
    /* %typemap(in) char **dict */
    HV *hv = (HV*)SvRV($input);
    SV *sv;
    char *key;
    I32 klen;
    $1 = NULL;
    hv_iterinit(hv);
    while(sv = hv_iternextsv(hv,&key,&klen)) {
        $1 = CSLAddNameValue( $1, key, SvPV_nolen(sv) );
    }
}
%typemap(out) char **dict
{
    /* %typemap(out) char **dict */
    char **stringarray = $1;
    HV *hv = (HV*)sv_2mortal((SV*)newHV());
    if ( stringarray != NULL ) {
        while (*stringarray != NULL ) {
            char const *valptr;
            char *keyptr;
            valptr = CPLParseNameValue( *stringarray, &keyptr );
            if ( valptr != 0 ) {
                hv_store(hv, keyptr, strlen(keyptr), newSVpv(valptr, strlen(valptr)), 0);
                CPLFree( keyptr );
            }
            stringarray++;
        }
    }
    $result = newRV((SV*)hv);
    sv_2mortal($result);
    argvi++;
}
%typemap(freearg) char **dict
{
    /* %typemap(freearg) char **dict */
    CSLDestroy( $1 );
}

/*
 * Typemap char **options <-> AV
 */
%typemap(typecheck,precedence=SWIG_TYPECHECK_POINTER) char **options
{
    /* %typemap(typecheck,precedence=SWIG_TYPECHECK_POINTER) char **options */
    $1 = 1;
}
%typemap(in, fragment="sv_to_utf8_string") char **options
{
    /* %typemap(in) char **options */
    if (SvOK($input)) {
        if (SvROK($input)) {
            if (SvTYPE(SvRV($input))==SVt_PVAV) {
                AV *av = (AV*)(SvRV($input));
                for (int i = 0; i < av_len(av)+1; i++) {
                    SV *sv = *(av_fetch(av, i, 0));
                    char *tmp = sv_to_utf8_string(sv, NULL);
                    $1 = CSLAddString($1, tmp);
                    free(tmp);
                }
            } else if (SvTYPE(SvRV($input))==SVt_PVHV) {
                HV *hv = (HV*)SvRV($input);
                SV *sv;
                char *key;
                I32 klen;
                $1 = NULL;
                hv_iterinit(hv);
                while(sv = hv_iternextsv(hv, &key, &klen)) {
                    char *tmp = sv_to_utf8_string(sv, NULL);
                    $1 = CSLAddNameValue($1, key, tmp);
                    free(tmp);
                }
            } else
                do_confess(NEED_REF, 1);
        } else
            do_confess(NEED_REF, 1);
    }
}
%typemap(freearg) char **options
{
    /* %typemap(freearg) char **options */
    if ($1) CSLDestroy( $1 );
}
%typemap(out) char **options
{
    /* %typemap(out) char **options -> ( string ) */
    AV* av = (AV*)sv_2mortal((SV*)newAV());
    char **stringarray = $1;
    if ( stringarray != NULL ) {
        int n = CSLCount( stringarray );
        for ( int i = 0; i < n; i++ ) {
            SV *sv = newSVpv(stringarray[i], 0);
            SvUTF8_on(sv); /* expecting UTF-8 from GDAL */
            if (!av_store(av, i, sv))
                SvREFCNT_dec(sv);
        }
    }
    $result = newRV((SV*)av);
    sv_2mortal($result);
    argvi++;
}

/*
 * Typemaps map mutable char ** arguments from AV.  Does not
 * return the modified argument
 */
%typemap(in, fragment="sv_to_utf8_string") (char **ignorechange) (char *val, U8 *tmpbuf = NULL)
{
    /* %typemap(in) (char **ignorechange) */
    val = sv_to_utf8_string($input, &tmpbuf);
    $1 = &val;
}
%typemap(freearg) (char **ignorechange)
{
    /* %typemap(freearg) (char **ignorechange) */
    if (tmpbuf$argnum) free(tmpbuf$argnum);
}

/*
 * Typemap for char **argout.
 */
%typemap(in,numinputs=0) (char **argout) (char *argout=0), (char **username) (char *argout=0), (char **usrname) (char *argout=0), (char **type) (char *argout=0)
{
    /* %typemap(in,numinputs=0) (char **argout) */
    $1 = &argout;
}
%typemap(argout) (char **argout), (char **username), (char **usrname), (char **type)
{
    /* %typemap(argout) (char **argout) */
    $result = sv_newmortal();
    if ( $1 ) {
        sv_setpv($result, *$1);
        SvUTF8_on($result); /* expecting UTF-8 from GDAL */
    }
    argvi++;
}
%typemap(freearg) (char **argout)
{
    /* %typemap(freearg) (char **argout) */
    if ( *$1 )
        CPLFree( *$1 );
}

/*
 * Typemap for an optional POD argument.
 * Declare function to take POD *.  If the parameter
 * is NULL then the function needs to define a default
 * value.
 */
%typemap(in) (int *optional_int) ( int val )
{
    /* %typemap(in) (int *optional_int) */
    if ( !SvOK($input) ) {
        $1 = 0;
    }
    else {
        val = SvIV($input);
        $1 = ($1_type)&val;
    }
}
%typemap(in) (GIntBig *optional_GIntBig) ( GIntBig val )
{
    /* %typemap(in) (GIntBig *optional_GIntBig) */
    if ( !SvOK($input) ) {
        $1 = 0;
    }
    else {
        val = CPLAtoGIntBig(SvPV_nolen($input));
        $1 = ($1_type)&val;
    }
}

/*
 * Typedef const char * <- Any object.
 *
 * Formats the object using str and returns the string representation
 */

%typemap(in, fragment="sv_to_utf8_string") (tostring argin) (U8 *tmpbuf = NULL)
{
    /* %typemap(in) (tostring argin) */
    $1 = sv_to_utf8_string($input, &tmpbuf);
}
%typemap(typecheck,precedence=SWIG_TYPECHECK_POINTER) (tostring argin)
{
    /* %typemap(typecheck,precedence=SWIG_TYPECHECK_POINTER) (tostring argin) */
    $1 = 1;
}
%typemap(freearg) (tostring argin)
{
    /* %typemap(freearg) (tostring argin) */
    if (tmpbuf$argnum) free(tmpbuf$argnum);
}

/*
 * Typemap for CPLErr.
 * The assumption is that all errors have been reported through CPLError
 * and are thus caught by call to CPLGetLastErrorType() in %exception
 */
%typemap(out) CPLErr
{
    /* %typemap(out) CPLErr */
}

/*
 * Typemap for OGRErr.
 * _Some_ errors in OGR are not reported through CPLError and the return
 * value of the function must be examined and the message obtained from
 * OGRErrMessages, which is a function within these wrappers.
 */
%import "ogr_error_map.i"
%typemap(out,fragment="OGRErrMessages") OGRErr
{
    /* %typemap(out) OGRErr */
    if ( result != 0 ) {
        const char *err = CPLGetLastErrorMsg();
        if (err and *err) do_confess(err, 0); /* this is usually better */
        do_confess( OGRErrMessages(result), 1 );
    }
}

/*
 * Typemaps for minixml:  CPLXMLNode* input, CPLXMLNode *ret
 */

%fragment("AVToXMLTree","header") %{
/************************************************************************/
/*                          AVToXMLTree()                               */
/************************************************************************/
    static CPLXMLNode *AVToXMLTree( AV *av, int *err )
    {
        int      nChildCount = 0, iChild, nType;
        CPLXMLNode *psThisNode;
        char       *pszText = NULL;

        nChildCount = av_len(av) - 1; /* There are two non-children in the array */
        if (nChildCount < 0) {
            /* the input XML is empty */
            *err = 1;
            return NULL;
        }

        nType = SvIV(*(av_fetch(av,0,0)));
        SV *sv = *(av_fetch(av,1,0));
        char *tmp = sv_to_utf8_string(sv, NULL);
        psThisNode = CPLCreateXMLNode(NULL, (CPLXMLNodeType)nType, tmp);
        free(tmp);

        for( iChild = 0; iChild < nChildCount; iChild++ )
        {
            SV **s = av_fetch(av, iChild+2, 0);
            CPLXMLNode *psChild;
            if (!(SvROK(*s) && (SvTYPE(SvRV(*s))==SVt_PVAV))) {
                /* expected a reference to an array */
                *err = 2;
                psChild = NULL;
            } else
                psChild = AVToXMLTree((AV*)SvRV(*s), err);
            if (psChild)
                CPLAddXMLChild( psThisNode, psChild );
            else {
                CPLDestroyXMLNode(psThisNode);
                return NULL;
            }
        }

        return psThisNode;
    }
    %}

%typemap(in,fragment="AVToXMLTree") (CPLXMLNode* xmlnode )
{
    /* %typemap(in) (CPLXMLNode* xmlnode ) */
    if (!(SvROK($input) && (SvTYPE(SvRV($input))==SVt_PVAV)))
        do_confess(NEED_ARRAY_REF, 1);
    AV *av = (AV*)(SvRV($input));
    int err;
    $1 = AVToXMLTree( av, &err );
    if ( !$1 ) {
        switch (err) {
        case 1:
            do_confess(ARRAY_TO_XML_FAILED " " NEED_DEF, 1);
        case 2:
            do_confess(ARRAY_TO_XML_FAILED " " NEED_ARRAY_REF, 1);
        }
    }
}
%typemap(freearg) (CPLXMLNode *xmlnode)
{
    /* %typemap(freearg) (CPLXMLNode *xmlnode) */
    if ( $1 ) CPLDestroyXMLNode( $1 );
}

%fragment("XMLTreeToAV","header") %{
/************************************************************************/
/*                          XMLTreeToAV()                               */
/************************************************************************/
    static AV *XMLTreeToAV( CPLXMLNode *psTree )
    {
        AV *av;
        int      nChildCount = 0, iChild;
        CPLXMLNode *psChild;

        for( psChild = psTree->psChild;
             psChild != NULL;
             psChild = psChild->psNext )
            nChildCount++;

        av = (AV*)sv_2mortal((SV*)newAV());

        av_store(av,0,newSViv((int) psTree->eType));
        SV *sv = newSVpv(psTree->pszValue, strlen(psTree->pszValue));
        SvUTF8_on(sv); /* expecting UTF-8 from GDAL */
        av_store(av,1,sv);

        for( psChild = psTree->psChild, iChild = 2;
             psChild != NULL;
             psChild = psChild->psNext, iChild++ )
        {
            SV *s = newRV((SV*)XMLTreeToAV(psChild));
            if (!av_store(av, iChild, s))
                SvREFCNT_dec(s);
        }

        return av;
    }
    %}

%typemap(out,fragment="XMLTreeToAV") (CPLXMLNode*)
{
    /* %typemap(out) (CPLXMLNode*) */
    $result = newRV((SV*)XMLTreeToAV( $1 ));
    sv_2mortal($result);
    argvi++;
}
%typemap(ret) (CPLXMLNode*)
{
    /* %typemap(ret) (CPLXMLNode*) */
    if ( $1 ) CPLDestroyXMLNode( $1 );
}

/* non NULL input pointer checks */

%define CHECK_NOT_UNDEF(type, param, msg)
%typemap(check) (type *param)
{
    /* %typemap(check) (type *param) */
    if (!$1)
        do_confess(NEED_DEF, 1);
}
%enddef

%define IF_UNDEF_SET_EMPTY_STRING(type, param)
%typemap(default) type param {
    /* %typemap(default) type param */
    $1 = (char *)"";
 }
%enddef

%define IF_UNDEF_NULL(type, param)
%typemap(default) type param {
    /* %typemap(default) type param */
    $1 = NULL;
 }
%enddef

CHECK_NOT_UNDEF(char, method, method)
CHECK_NOT_UNDEF(const char, name, name)
CHECK_NOT_UNDEF(const char, request, request)
CHECK_NOT_UNDEF(const char, cap, capability)
CHECK_NOT_UNDEF(const char, statement, statement)
CHECK_NOT_UNDEF(const char, pszNewDesc, description)
CHECK_NOT_UNDEF(OSRCoordinateTransformationShadow, , coordinate transformation)
CHECK_NOT_UNDEF(OGRGeometryShadow, other, other geometry)
CHECK_NOT_UNDEF(OGRGeometryShadow, other_disown, other geometry)
CHECK_NOT_UNDEF(OGRGeometryShadow, geom, geometry)
CHECK_NOT_UNDEF(OGRFieldDefnShadow, defn, field definition)
CHECK_NOT_UNDEF(OGRFieldDefnShadow, field_defn, field definition)
CHECK_NOT_UNDEF(OGRFeatureShadow, feature, feature)

IF_UNDEF_SET_EMPTY_STRING(const char *, utf8_path)

IF_UNDEF_NULL(const char *, target_key)

%typemap(in, numinputs=1) (int nCount, double *x, double *y, double *z)
{
    /* %typemap(in) (int nCount, double *x, double *y, double *z) */
    /* $input is a ref to a list of refs to point lists */
    if (! (SvROK($input) && (SvTYPE(SvRV($input))==SVt_PVAV)))
        do_confess(NEED_ARRAY_REF, 1);
    AV *av = (AV*)(SvRV($input));
    $1 = av_len(av)+1;
    $2 = (double*)CPLMalloc($1*sizeof(double));
    if ($2)
        $3 = (double*)CPLMalloc($1*sizeof(double));
    if ($2 && $3)
        $4 = (double*)CPLMalloc($1*sizeof(double));
    if (!$2 or !$3 or !$4)
        SWIG_fail;
    for (int i = 0; i < $1; i++) {
        SV **sv = av_fetch(av, i, 0); /* ref to one point list */
        if (!(SvROK(*sv) && (SvTYPE(SvRV(*sv))==SVt_PVAV)))
            do_confess(WRONG_ITEM_IN_ARRAY, 1);
        AV *ac = (AV*)(SvRV(*sv));
        int n = av_len(ac)+1;
        SV **c = av_fetch(ac, 0, 0);
        $2[i] = SvNV(*c);
        c = av_fetch(ac, 1, 0);
        $3[i] = SvNV(*c);
        if (n < 3) {
            $4[i] = 0;
        } else {
            c = av_fetch(ac, 2, 0);
            $4[i] = SvNV(*c);
        }
    }
}

%typemap(argout) (int nCount, double *x, double *y, double *z)
{
    /* %typemap(argout) (int nCount, double *x, double *y, double *z) */
    AV *av = (AV*)(SvRV($input));
    for (int i = 0; i < $1; i++) {
        SV **sv = av_fetch(av, i, 0);
        AV *ac = (AV*)(SvRV(*sv));
        int n = av_len(ac)+1;
        SV *c = newSVnv($2[i]);
        if (!av_store(ac, 0, c))
            SvREFCNT_dec(c);
        c = newSVnv($3[i]);
        if (!av_store(ac, 1, c))
            SvREFCNT_dec(c);
        c = newSVnv($4[i]);
        if (!av_store(ac, 2, c))
            SvREFCNT_dec(c);
    }
}

%typemap(freearg) (int nCount, double *x, double *y, double *z)
{
    /* %typemap(freearg) (int nCount, double *x, double *y, double *z) */
    CPLFree($2);
    CPLFree($3);
    CPLFree($4);
}

%typemap(arginit, noblock=1) ( void* callback_data = NULL)
{
    /* %typemap(arginit, noblock=1) ( void* callback_data = NULL) */
    SavedEnv saved_env;
    saved_env.fct = NULL;
    saved_env.data = &PL_sv_undef;
    $1 = (void *)(&saved_env);
}

%typemap(in) (GDALProgressFunc callback = NULL)
{
    /* %typemap(in) (GDALProgressFunc callback = NULL) */
    if (SvOK($input)) {
        if (SvROK($input)) {
            if (SvTYPE(SvRV($input)) != SVt_PVCV) {
                do_confess(NEED_CODE_REF, 1);
            } else {
                saved_env.fct = (SV *)$input;
                $1 = &callback_d_cp_vp;
            }
        } else {
            do_confess(NEED_CODE_REF, 1);
        }
    }
}

%typemap(in) (void* callback_data = NULL)
{
    /* %typemap(in) (void* callback_data=NULL) */
    if (SvOK($input))
        saved_env.data = (SV *)$input;
}

%typemap(in, numinputs=1) (VSIWriteFunction pFct, FILE* stream = NULL)
{
    /* %typemap(in) (VSIWriteFunction pFct) */
    if (VSIStdoutSetRedirectionFct != &PL_sv_undef) {
        SvREFCNT_dec(VSIStdoutSetRedirectionFct);
    }
    if (SvOK($input)) {
        if (SvROK($input)) {
            if (SvTYPE(SvRV($input)) != SVt_PVCV) {
                do_confess(NEED_CODE_REF, 1);
            } else {
                VSIStdoutSetRedirectionFct = newRV_inc(SvRV((SV *)$input));
                $1 = &callback_fwrite;
            }
        } else {
            do_confess(NEED_CODE_REF, 1);
        }
    } else
        VSIStdoutSetRedirectionFct = &PL_sv_undef;
}

%typemap(in) (GDALDatasetShadow *)
{
    /* %typemap(in) (GDALDatasetShadow *) */
    void *argp = 0;
    int res = SWIG_ConvertPtr($input, &argp, SWIGTYPE_p_GDALDatasetShadow, 0 |  0 );
    if (!SWIG_IsOK(res)) {
        do_confess(WRONG_CLASS, 1);
    }
    $1 = reinterpret_cast< GDALDatasetShadow * >(argp);
    if ($1 == NULL)
        do_confess(NEED_DEF, 1);
}

%typemap(in, numinputs=1) (int object_list_count, GDALDatasetShadow **poObjects)
{
    /* %typemap(in, numinputs=1) (int object_list_count, GDALDatasetShadow** poObjects) */
    if (!(SvROK($input) && (SvTYPE(SvRV($input))==SVt_PVAV)))
        do_confess(NEED_ARRAY_REF, 1);
    AV *av = (AV*)(SvRV($input));
    $1 = av_len(av)+1;
    /* get the pointers from the array */
    $2 = (GDALDatasetShadow **)CPLMalloc($1*sizeof(GDALDatasetShadow *));
    if ($2) {
        for (int i = 0; i < $1; i++) {
            SV **sv = av_fetch(av, i, 0);
            int ret = SWIG_ConvertPtr(*sv, &($2[i]), SWIGTYPE_p_GDALDatasetShadow, 0);
            if (!SWIG_IsOK(ret))
                do_confess(WRONG_ITEM_IN_ARRAY, 1);
        }
    } else
        do_confess(OUT_OF_MEMORY, 1);
}


/*
 * Typemaps for VSIStatL
 */
%typemap(in,numinputs=0) (VSIStatBufL *) (VSIStatBufL sStatBuf)
{
    /* %typemap(in,numinputs=0) (VSIStatBufL *) (VSIStatBufL sStatBuf) */
    $1 = &sStatBuf;
}
%typemap(argout) (VSIStatBufL *)
{
    /* %typemap(argout) (VSIStatBufL *) */
    char mode[2];
    mode[0] = ' ';
    mode[1] = '\0';
    if (S_ISREG(sStatBuf2.st_mode)) mode[0] = 'f';
    else if (S_ISDIR(sStatBuf2.st_mode)) mode[0] = 'd';
    else if (S_ISLNK(sStatBuf2.st_mode)) mode[0] = 'l';
    else if (S_ISFIFO(sStatBuf2.st_mode)) mode[0] = 'p';
    else if (S_ISSOCK(sStatBuf2.st_mode)) mode[0] = 'S';
    else if (S_ISBLK(sStatBuf2.st_mode)) mode[0] = 'b';
    else if (S_ISCHR(sStatBuf2.st_mode)) mode[0] = 'c';
    EXTEND(SP, argvi+2-items+1);
    ST(argvi++) = sv_2mortal(newSVpv(mode, 0));
    ST(argvi++) = sv_2mortal(newSVuv(sStatBuf2.st_size));
}

/*
 * Typemaps for VSIFReadL
 */
%typemap(in,numinputs=1) (void *pBuffer, size_t nSize, size_t nCount)
{
    /* %typemap(in,numinputs=1) (void *pBuffer, size_t nSize, size_t nCount) */
    size_t len = SvIV($input);
    $1 = CPLMalloc(len);
    if (!$1)
        SWIG_fail;
    $2 = 1;
    $3 = len;
}
%typemap(argout) (void *pBuffer, size_t nSize, size_t nCount)
{
    /* %typemap(argout) (void *pBuffer, size_t nSize, size_t nCount) */
    if (result) {
        $result = sv_2mortal(newSVpvn((char*)$1, result));
    } else {
        $result = &PL_sv_undef;
    }
    CPLFree($1);
    argvi++;
}
%typemap(out) (size_t VSIFReadL)
{
    /* %typemap(out) (size_t VSIFReadL) */
}

/*
 * Typemaps for VSIFWriteL
 */
%typemap(in,numinputs=1) (const void *pBuffer, size_t nSize, size_t nCount)
{
    /* %typemap(in,numinputs=1) (const void *pBuffer, size_t nSize, size_t nCount) */
    size_t len;
    $1 = SvPV($input, len);
    $2 = 1;
    $3 = len;
}

/*
 * Typemaps for ensuring UTF-8 is given to GDAL if requested impacts:
 * (ogr:) Driver_CreateDataSource, Driver_CopyDataSource, Driver_Open,
 * Driver_DeleteDataSource Open, OpenShared,
 * DataSource__GetLayerByName, DataSource__CreateLayer,
 * Feature_GetFieldDefnRef__SWIG_1, Feature_IsFieldSet__SWIG_1,
 * Feature_GetFieldIndex (gdal:) PushFinderLocation, FindFile,
 * ReadDir, FileFromMemBuffer, Unlink, MkDir, RmDir, Stat VSIFOpenL,
 * Driver__Create, Driver_CreateCopy, Driver_Delete, Open__SWIG_1,
 * OpenShared__SWIG_1, IdentifyDriver
 */
%typemap(in, numinputs=1, fragment="sv_to_utf8_string") (const char* utf8_path) (U8 *tmpbuf = NULL)
{
    /* %typemap(in,numinputs=1) (const char* utf8_path) (U8 *tmpbuf) */
    $1 = sv_to_utf8_string($input, &tmpbuf);
}
%typemap(freearg) (const char* utf8_path)
{
    /* %typemap(freearg) (const char* utf8_path) */
    if (tmpbuf$argnum) free(tmpbuf$argnum);
}

%typemap(in, numinputs=1, fragment="sv_to_utf8_string") (const char* layer_name) (U8 *tmpbuf = NULL)
{
    /* %typemap(in,numinputs=1) (const char* layer_name) */
    $1 = sv_to_utf8_string($input, &tmpbuf);
}
%typemap(freearg) (const char* layer_name)
{
    /* %typemap(freearg) (const char* layer_name) */
    if (tmpbuf$argnum) free(tmpbuf$argnum);
}

%typemap(in, numinputs=1, fragment="sv_to_utf8_string") (const char* name) (U8 *tmpbuf = NULL)
{
    /* %typemap(in,numinputs=1) (const char* name) */
    $1 = sv_to_utf8_string($input, &tmpbuf);
}
%typemap(freearg) (const char* name)
{
    /* %typemap(freearg) (const char* name) */
    if (tmpbuf$argnum) free(tmpbuf$argnum);
}

%typemap(in,numinputs=0) (int *pnBytes) (int bytes)
{
    /* %typemap(in,numinputs=0) (int *pnBytes) (int bytes) */
    $1 = &bytes;
}
%typemap(out) GByte *
{
    /* %typemap(out) GByte * */
    $result = sv_newmortal();
    sv_setpvn($result, (const char*)$1, *arg2);
    CPLFree($1);
    argvi++;
}

%typemap(in,numinputs=1) (int object_list_count, GDALRasterBandShadow **poObjects)
{
    /* %typemap(in,numinputs=1) (int object_list_count, GDALRasterBandShadow **poObjects) */
    if (!(SvROK($input) && (SvTYPE(SvRV($input))==SVt_PVAV)))
        do_confess(NEED_ARRAY_REF, 1);
    AV *av = (AV*)(SvRV($input));
    $1 = av_len(av)+1;
    /* get the pointers from the array into bands */
    $2 = (GDALRasterBandShadow **)CPLMalloc($1*sizeof(GDALRasterBandShadow *));
    if ($2) {
        for (int i = 0; i < $1; i++) {
            SV **sv = av_fetch(av, i, 0);
            int ret = SWIG_ConvertPtr(*sv, &($2[i]), SWIGTYPE_p_GDALRasterBandShadow, 0);
            if (!SWIG_IsOK(ret))
                do_confess(WRONG_ITEM_IN_ARRAY, 1);
        }
    } else
        do_confess(OUT_OF_MEMORY, 1);

}
%typemap(freearg) (int object_list_count, GDALRasterBandShadow **poObjects)
{
    /* %typemap(freearg) (int object_list_count, GDALRasterBandShadow **poObjects) */
    CPLFree($2);
}

%typemap(in,numinputs=1) (int nBytes, GByte* pabyBuf)
{
    /* %typemap(in,numinputs=1) (int nBytes, GByte* pabyBuf) */
    $1 = SvCUR($input);
    $2 = (GByte*)SvPV_nolen($input);
}

%typemap(typecheck, precedence=SWIG_TYPECHECK_INTEGER) int nBytes, GByte* pabyBuf
{
    /* %typemap(typecheck, precedence=SWIG_TYPECHECK_INTEGER) int nBytes, GByte* pabyBuf */
   $1 = 1;
}
