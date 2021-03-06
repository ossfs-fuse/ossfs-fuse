#ifndef OSSFS_OSS_H_
#define OSSFS_OSS_H_

#define FUSE_USE_VERSION      26
#define UPLOAD_THRESHOLD_SIZE 104857600LL // 100M this value must be smaller than
                                          // 1GB accroding to OSS's limitation

#include <fuse.h>

#define OSSFS_FUSE_EXIT() { \
  struct fuse_context* pcxt = fuse_get_context(); \
  if(pcxt){ \
    fuse_exit(pcxt->fuse); \
  } \
}

//
// ossfs use many small allocated chunk in heap area for
// stats cache and parsing xml, etc. The OS may decide
// that giving this little memory back to the kernel
// will cause too much overhead and delay the operation.
// So ossfs calls malloc_trim function to really get the
// memory back. Following macros is prepared for that
// your system does not have it.
//
// Address of gratitude, this workaround quotes a document
// of libxml2.
// http://xmlsoft.org/xmlmem.html
//
#ifdef HAVE_MALLOC_TRIM

#include <malloc.h>

#define DISPWARN_MALLOCTRIM(str)
#define OSSFS_MALLOCTRIM(pad)          malloc_trim(pad)
#define OSSFS_XMLFREEDOC(doc) \
        { \
          xmlFreeDoc(doc); \
          OSSFS_MALLOCTRIM(0); \
        }
#define OSSFS_XMLFREE(ptr) \
        { \
          xmlFree(ptr); \
          OSSFS_MALLOCTRIM(0); \
        }
#define OSSFS_XMLXPATHFREECONTEXT(ctx) \
        { \
          xmlXPathFreeContext(ctx); \
          OSSFS_MALLOCTRIM(0); \
        }
#define OSSFS_XMLXPATHFREEOBJECT(obj) \
        { \
          xmlXPathFreeObject(obj); \
          OSSFS_MALLOCTRIM(0); \
        }

#else // HAVE_MALLOC_TRIM

#define DISPWARN_MALLOCTRIM(str) \
        fprintf(stderr, "Warning: %s without malloc_trim is possibility of the use memory increase.\n", program_name.c_str())
#define OSSFS_MALLOCTRIM(pad)
#define OSSFS_XMLFREEDOC(doc)          xmlFreeDoc(doc)
#define OSSFS_XMLFREE(ptr)             xmlFree(ptr)
#define OSSFS_XMLXPATHFREECONTEXT(ctx) xmlXPathFreeContext(ctx)
#define OSSFS_XMLXPATHFREEOBJECT(obj)  xmlXPathFreeObject(obj)

#endif // HAVE_MALLOC_TRIM

#endif // OSSFS_OSS_H_
