// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;

codeunit 139635 "Shpfy Variant Option Name Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        IsInitialized: Boolean;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    procedure UnitTestShopifyOriginProductInheritsOption1Name()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        ExistingVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductExport: Codeunit "Shpfy Product Export";
        ProductId: BigInteger;
    begin
        // [SCENARIO] Shopify-origin product with one existing variant having Option 1 Name = 'Size'
        // → new BC variant export inherits 'Size' and sets Option 1 Value = ItemVariant.Code
        Initialize();

        // [GIVEN] A product id
        ProductId := Any.IntegerInRange(100000, 199999);

        // [GIVEN] One existing Shpfy Variant for that product with Option 1 Name = 'Size'
        ExistingVariant.Init();
        ExistingVariant.Id := ProductInitTest.GetShopifyVariantId();
        ExistingVariant."Product Id" := ProductId;
        ExistingVariant."Option 1 Name" := 'Size';
        ExistingVariant."Option 1 Value" := 'M';
        ExistingVariant."Shop Code" := Shop.Code;
        ExistingVariant.Insert();

        // [GIVEN] An item with at least one item variant
        Item := ProductInitTest.CreateItem(Shop."Item Templ. Code", Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2), true);
        ItemVariant.SetRange("Item No.", Item."No.");
        ItemVariant.FindFirst();

        // [GIVEN] A new Shpfy Variant (temp, Option 1 Name blank) for the same product
        TempShopifyVariant.Init();
        TempShopifyVariant.Id := ProductInitTest.GetShopifyVariantId();
        TempShopifyVariant."Product Id" := ProductId;
        TempShopifyVariant."Shop Code" := Shop.Code;
        TempShopifyVariant."Item SystemId" := Item.SystemId;
        TempShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;

        // [WHEN] FillInProductVariantData is called
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(TempShopifyVariant, Item, ItemVariant);

        // [THEN] Option 1 Name is inherited from the existing variant
        LibraryAssert.AreEqual('Size', TempShopifyVariant."Option 1 Name", 'Option 1 Name should be inherited as ''Size''');

        // [THEN] Option 1 Value is set from ItemVariant.Code
        LibraryAssert.AreEqual(ItemVariant.Code, TempShopifyVariant."Option 1 Value", 'Option 1 Value should equal ItemVariant.Code');
    end;

    [Test]
    procedure UnitTestBCOriginProductDefaultsToVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        ExistingVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductExport: Codeunit "Shpfy Product Export";
        ProductId: BigInteger;
    begin
        // [SCENARIO] BC-origin product where all existing variants already carry Option 1 Name = 'Variant'
        // → new variant still gets 'Variant' (regression guard)
        Initialize();

        // [GIVEN] A product id
        ProductId := Any.IntegerInRange(200000, 299999);

        // [GIVEN] Existing Shpfy Variant for that product with Option 1 Name = 'Variant'
        ExistingVariant.Init();
        ExistingVariant.Id := ProductInitTest.GetShopifyVariantId();
        ExistingVariant."Product Id" := ProductId;
        ExistingVariant."Option 1 Name" := 'Variant';
        ExistingVariant."Option 1 Value" := 'BLUE';
        ExistingVariant."Shop Code" := Shop.Code;
        ExistingVariant.Insert();

        // [GIVEN] An item with at least one item variant
        Item := ProductInitTest.CreateItem(Shop."Item Templ. Code", Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2), true);
        ItemVariant.SetRange("Item No.", Item."No.");
        ItemVariant.FindFirst();

        // [GIVEN] A new Shpfy Variant (temp, Option 1 Name blank) for the same product
        TempShopifyVariant.Init();
        TempShopifyVariant.Id := ProductInitTest.GetShopifyVariantId();
        TempShopifyVariant."Product Id" := ProductId;
        TempShopifyVariant."Shop Code" := Shop.Code;
        TempShopifyVariant."Item SystemId" := Item.SystemId;
        TempShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;

        // [WHEN] FillInProductVariantData is called
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(TempShopifyVariant, Item, ItemVariant);

        // [THEN] Option 1 Name resolves to 'Variant' (same as existing variants)
        LibraryAssert.AreEqual('Variant', TempShopifyVariant."Option 1 Name", 'Option 1 Name should default to ''Variant''');
    end;

    [Test]
    procedure UnitTestNoExistingVariantsDefaultsToVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductExport: Codeunit "Shpfy Product Export";
        ProductId: BigInteger;
    begin
        // [SCENARIO] Product with no existing Shpfy Variant rows → Option 1 Name defaults to 'Variant'
        Initialize();

        // [GIVEN] A product id with no existing Shpfy Variant records
        ProductId := Any.IntegerInRange(300000, 399999);

        // [GIVEN] An item with at least one item variant
        Item := ProductInitTest.CreateItem(Shop."Item Templ. Code", Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2), true);
        ItemVariant.SetRange("Item No.", Item."No.");
        ItemVariant.FindFirst();

        // [GIVEN] A new Shpfy Variant (temp, Option 1 Name blank) for a product with no existing variants
        TempShopifyVariant.Init();
        TempShopifyVariant.Id := ProductInitTest.GetShopifyVariantId();
        TempShopifyVariant."Product Id" := ProductId;
        TempShopifyVariant."Shop Code" := Shop.Code;
        TempShopifyVariant."Item SystemId" := Item.SystemId;
        TempShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;

        // [WHEN] FillInProductVariantData is called
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(TempShopifyVariant, Item, ItemVariant);

        // [THEN] Option 1 Name defaults to 'Variant'
        LibraryAssert.AreEqual('Variant', TempShopifyVariant."Option 1 Name", 'Option 1 Name should default to ''Variant'' when no existing variants');
    end;

    [Test]
    procedure UnitTestAmbiguousOption1NameFallsBackToVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        ExistingVariant: Record "Shpfy Variant";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductExport: Codeunit "Shpfy Product Export";
        ProductId: BigInteger;
    begin
        // [SCENARIO] Two existing variants with different Option 1 Names → falls back to 'Variant'
        Initialize();

        // [GIVEN] A product id
        ProductId := Any.IntegerInRange(400000, 499999);

        // [GIVEN] First existing variant with Option 1 Name = 'Size'
        ExistingVariant.Init();
        ExistingVariant.Id := ProductInitTest.GetShopifyVariantId();
        ExistingVariant."Product Id" := ProductId;
        ExistingVariant."Option 1 Name" := 'Size';
        ExistingVariant."Option 1 Value" := 'S';
        ExistingVariant."Shop Code" := Shop.Code;
        ExistingVariant.Insert();

        // [GIVEN] Second existing variant with Option 1 Name = 'Color' (ambiguous)
        ExistingVariant.Init();
        ExistingVariant.Id := ProductInitTest.GetShopifyVariantId();
        ExistingVariant."Product Id" := ProductId;
        ExistingVariant."Option 1 Name" := 'Color';
        ExistingVariant."Option 1 Value" := 'Red';
        ExistingVariant."Shop Code" := Shop.Code;
        ExistingVariant.Insert();

        // [GIVEN] An item with at least one item variant
        Item := ProductInitTest.CreateItem(Shop."Item Templ. Code", Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2), true);
        ItemVariant.SetRange("Item No.", Item."No.");
        ItemVariant.FindFirst();

        // [GIVEN] A new Shpfy Variant (temp, Option 1 Name blank) for the same product
        TempShopifyVariant.Init();
        TempShopifyVariant.Id := ProductInitTest.GetShopifyVariantId();
        TempShopifyVariant."Product Id" := ProductId;
        TempShopifyVariant."Shop Code" := Shop.Code;
        TempShopifyVariant."Item SystemId" := Item.SystemId;
        TempShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;

        // [WHEN] FillInProductVariantData is called
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(TempShopifyVariant, Item, ItemVariant);

        // [THEN] Option 1 Name falls back to 'Variant' because existing variants disagree
        LibraryAssert.AreEqual('Variant', TempShopifyVariant."Option 1 Name", 'Option 1 Name should fall back to ''Variant'' when existing variants are ambiguous');
    end;

    [Test]
    procedure UnitTestUpdatePathKeepsExistingOption1Name()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductExport: Codeunit "Shpfy Product Export";
        ProductId: BigInteger;
    begin
        // [SCENARIO] Update path: existing Shpfy Variant already has Option 1 Name = 'Color'
        // → name is not reset; Option 1 Value is correctly set to ItemVariant.Code
        Initialize();

        // [GIVEN] A product id
        ProductId := Any.IntegerInRange(500000, 599999);

        // [GIVEN] An item with at least one item variant
        Item := ProductInitTest.CreateItem(Shop."Item Templ. Code", Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2), true);
        ItemVariant.SetRange("Item No.", Item."No.");
        ItemVariant.FindFirst();

        // [GIVEN] A Shpfy Variant that already has Option 1 Name = 'Color' (update path)
        TempShopifyVariant.Init();
        TempShopifyVariant.Id := ProductInitTest.GetShopifyVariantId();
        TempShopifyVariant."Product Id" := ProductId;
        TempShopifyVariant."Shop Code" := Shop.Code;
        TempShopifyVariant."Item SystemId" := Item.SystemId;
        TempShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;
        TempShopifyVariant."Option 1 Name" := 'Color';
        TempShopifyVariant."Option 1 Value" := ItemVariant.Code;

        // [WHEN] FillInProductVariantData is called
        ProductExport.SetShop(Shop);
        ProductExport.FillInProductVariantData(TempShopifyVariant, Item, ItemVariant);

        // [THEN] Option 1 Name is not changed - remains 'Color'
        LibraryAssert.AreEqual('Color', TempShopifyVariant."Option 1 Name", 'Option 1 Name should remain ''Color'' on the update path');

        // [THEN] Option 1 Value is set to ItemVariant.Code
        LibraryAssert.AreEqual(ItemVariant.Code, TempShopifyVariant."Option 1 Value", 'Option 1 Value should equal ItemVariant.Code');
    end;

    local procedure Initialize()
    begin
        Any.SetDefaultSeed();
        if IsInitialized then
            exit;
        Shop := InitializeTest.CreateShop();
        Commit();
        IsInitialized := true;
    end;
}
