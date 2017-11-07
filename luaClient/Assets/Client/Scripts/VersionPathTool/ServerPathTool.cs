﻿// ------------------------------------------------------------------------------
//  <autogenerated>
//      This code was generated by a tool.
//      Mono Runtime Version: 4.0.30319.1
// 
//      Changes to this file may cause incorrect behavior and will be lost if 
//      the code is regenerated.
//  </autogenerated>
// ------------------------------------------------------------------------------
using System;
using UnityEngine;

public class ServerPathTool
{

	//更新版本静态资源服务器目录
	public static string  NewVersionStaticReDataPath{
		get {
			return ResDataPath + "/" + AssetFileTool.staticMainFest+ "/" + VersionTool.Instance.currentVersionCell.AppCode+"/";
		}
	}

	//更新版本动态资源服务器目录
	public static string NewVersionDynamicResDataPath{
		get {
			return ResDataPath + "/" + AssetFileTool.dynamicMainFest;
		}
	}


	public static string ResDataPath{
		get {
			#if UNITY_IOS
			return serverResIp+"/res/ios/";
			#elif UNITY_ANDROID
			return serverResIp+"/res/android/";
			#else
			return serverResIp+"/res/pc/";
			#endif
			}
	}

	public static string serverResIp = "http://localhost:8000/client";

}