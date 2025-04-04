#include "rar.hpp"

DWORD WinNT()
{
  static int dwPlatformId=-1;
  static DWORD dwMajorVersion,dwMinorVersion;
  if (dwPlatformId==-1)
  {
    OSVERSIONINFO WinVer;
    WinVer.dwOSVersionInfoSize=sizeof(WinVer);
    GetVersionEx(&WinVer);
    dwPlatformId=WinVer.dwPlatformId;
    dwMajorVersion=WinVer.dwMajorVersion;
    dwMinorVersion=WinVer.dwMinorVersion;

  }
  DWORD Result=0;
  if (dwPlatformId==VER_PLATFORM_WIN32_NT)
    Result=dwMajorVersion*0x100+dwMinorVersion;


  return Result;
}


// Replace it with documented Windows 11 check when available.
#include <comdef.h>
#include <wbemidl.h>
#pragma comment(lib, "wbemuuid.lib")

BSTR _com_util::ConvertStringToBSTR(const char* pSrc)
{
  if(!pSrc)
    return NULL;

  DWORD cwch;
  BSTR wsOut(NULL);

  if(cwch = ::MultiByteToWideChar(CP_ACP, 0, pSrc, -1, NULL, 0))
  {
    //get size minus NULL terminator
    cwch--;
    wsOut = ::SysAllocStringLen(NULL, cwch);

    if(wsOut)
    {
      if(!::MultiByteToWideChar(CP_ACP, 0, pSrc, -1, wsOut, cwch))
      {
        if(ERROR_INSUFFICIENT_BUFFER == ::GetLastError())
          return wsOut;
        ::SysFreeString(wsOut);//must clean up

        wsOut = NULL;
      }
    }
  }

  return wsOut;
};

static bool WMI_IsWindows10()
{
  IWbemLocator *pLoc = NULL;

  HRESULT hres = CoCreateInstance(CLSID_WbemLocator,0,CLSCTX_INPROC_SERVER,
                          IID_IWbemLocator,(LPVOID *)&pLoc);
 
  if (FAILED(hres))
    return false;

  IWbemServices *pSvc = NULL;
 
  hres = pLoc->ConnectServer(_bstr_t(L"ROOT\\CIMV2"),NULL,NULL,NULL,0,NULL,NULL,&pSvc);
    
  if (FAILED(hres))
  {
    pLoc->Release();     
    return false;
  }

  hres = CoSetProxyBlanket(pSvc,RPC_C_AUTHN_WINNT,RPC_C_AUTHZ_NONE,NULL,
         RPC_C_AUTHN_LEVEL_CALL,RPC_C_IMP_LEVEL_IMPERSONATE,NULL,EOAC_NONE);

  if (FAILED(hres))
  {
    pSvc->Release();
    pLoc->Release();     
    return false;
  }

  IEnumWbemClassObject *pEnumerator = NULL;
  hres = pSvc->ExecQuery(bstr_t("WQL"), bstr_t("SELECT * FROM Win32_OperatingSystem"),
         WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY, NULL, &pEnumerator);
    
  if (FAILED(hres) || pEnumerator==NULL)
  {
    pSvc->Release();
    pLoc->Release();
    return false;
  }

  bool Win10=false;

  IWbemClassObject *pclsObj = NULL;
  ULONG uReturn = 0;
  pEnumerator->Next(WBEM_INFINITE, 1, &pclsObj, &uReturn);
  if (pclsObj!=NULL && uReturn>0)
  {
    VARIANT vtProp;
    pclsObj->Get(L"Name", 0, &vtProp, 0, 0);
    Win10|=wcsstr(vtProp.bstrVal,L"Windows 10")!=NULL;
    VariantClear(&vtProp);
    pclsObj->Release();
  }

  pSvc->Release();
  pLoc->Release();
  pEnumerator->Release();

  return Win10;
}


// Replace it with actual check when available.
bool IsWindows11OrGreater()
{
  static bool IsSet=false,IsWin11=false;
  if (!IsSet)
  {
    OSVERSIONINFO WinVer;
    WinVer.dwOSVersionInfoSize=sizeof(WinVer);
    GetVersionEx(&WinVer);
    IsWin11=WinVer.dwMajorVersion>10 || 
          WinVer.dwMajorVersion==10 && WinVer.dwBuildNumber >= 22000 && !WMI_IsWindows10();
    IsSet=true;
  }
  return IsWin11;
}
