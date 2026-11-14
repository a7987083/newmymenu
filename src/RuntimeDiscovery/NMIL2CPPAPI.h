#pragma once
#include <stddef.h>
#include <stdint.h>
// Native declarations follow the audited native baseline, not guessed metadata layouts.
typedef struct {
    void *(*domainGet)(void);
    const void **(*domainGetAssemblies)(const void *,size_t *);
    const void *(*assemblyGetImage)(const void *);
    const char *(*imageGetName)(const void *);
    size_t (*imageGetClassCount)(const void *);
    void *(*imageGetClass)(const void *,size_t);
    const char *(*classGetName)(void *);
    const char *(*classGetNamespace)(void *);
    const void *(*classGetType)(void *);
    const void *(*classGetMethods)(void *,void **);
    const char *(*methodGetName)(const void *);
    uint32_t (*methodGetParamCount)(const void *);
    const void *(*methodGetParam)(const void *,uint32_t);
    const void *(*methodGetReturnType)(const void *);
    uint32_t (*methodGetFlags)(const void *,uint32_t *);
    char *(*typeGetName)(const void *);
    void (*freeMemory)(void *);
    void *(*threadCurrent)(void);
    void *(*threadAttach)(void *);
    void (*threadDetach)(void *);
} NMIL2CPPAPI;
#define NM_IL2CPP_API_FIELDS(M) \
 M(domainGet,"il2cpp_domain_get") \
 M(domainGetAssemblies,"il2cpp_domain_get_assemblies") \
 M(assemblyGetImage,"il2cpp_assembly_get_image") \
 M(imageGetName,"il2cpp_image_get_name") \
 M(imageGetClassCount,"il2cpp_image_get_class_count") \
 M(imageGetClass,"il2cpp_image_get_class") \
 M(classGetName,"il2cpp_class_get_name") \
 M(classGetNamespace,"il2cpp_class_get_namespace") \
 M(classGetType,"il2cpp_class_get_type") \
 M(classGetMethods,"il2cpp_class_get_methods") \
 M(methodGetName,"il2cpp_method_get_name") \
 M(methodGetParamCount,"il2cpp_method_get_param_count") \
 M(methodGetParam,"il2cpp_method_get_param") \
 M(methodGetReturnType,"il2cpp_method_get_return_type") \
 M(methodGetFlags,"il2cpp_method_get_flags") \
 M(typeGetName,"il2cpp_type_get_name") \
 M(freeMemory,"il2cpp_free") \
 M(threadCurrent,"il2cpp_thread_current") \
 M(threadAttach,"il2cpp_thread_attach") \
 M(threadDetach,"il2cpp_thread_detach")
