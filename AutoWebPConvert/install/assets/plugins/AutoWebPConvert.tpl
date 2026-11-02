//<?php
/**
 * WebP自動変換
 *
 * リソース内のコンテンツまたはテンプレート変数にある画像をWebPに変換する
 *
 * @category   plugin
 * @version    1.0.3
 * @license    GNU General Public License (GPL), https://www.gnu.org/licenses/gpl-3.0.html
 * @author     Yu.No (https://github.com/yuno25211415)
 * @lastupdate 2026/03/22
 * @internal @events OnDocFormSave
 * @internal @properties &overwrite=上書き;checkbox;上書きする;上書きする;対象画像ファイルが既にWebPとして存在する場合、上書きするかどうかを設定します。; &optQuality=品質;text;;;0-100の間で指定します。 &optEncoding=エンコーディング;list;,auto,lossless,lossy;;
 * @internal @modx_category Custom
 * @internal @installset base, sample
 * @internal @disabled 1
 * @todo Evolution CMSの`WebPConvert::convert`の機能を使用している。
 */

$ev = $modx->event;
$evName = $ev->name;
$basePath = $modx->config['base_path'];

if ($evName != 'OnDocFormSave') return;

use WebPConvert\WebPConvert;

// リソースの本文内のimgタグを抽出
preg_match_all('/<(img|source)\s+([^>]+)>/', $ev->params['doc']['content'], $matches);

if (!isset($matches[2]) || count($matches[2]) == 0) return;

// imgタグのsrc属性値のみ抽出
$paths = array_map(fn ($x) => preg_replace('/.*?src(set)?=["\']?([^"\']*)["\']?.*?$/', '$2', trim($x)), $matches[2]);

// データベースから画像のテンプレート変数値を取得
$db = evo()->db;
$tvsTableName = $db->getFullTableName('site_tmplvars');
$tvCvTableName = $db->getFullTableName('site_tmplvar_contentvalues');
$query = "SELECT tvcv.contentid as cid, tvcv.value as path FROM $tvsTableName as tvs INNER JOIN $tvCvTableName as tvcv ON tvs.id = tvcv.tmplvarid WHERE tvcv.contentid=$id AND tvs.type='image' AND NOT tvcv.value REGEXP '^[[:space:]]+$'";

$dbResults = $db->query($query);

if ($db->getRecordCount($dbResults) == 0) return;

foreach ($dbResults->fetchAll() as $row) $paths[] = $row['path'];

$dbResults = null;

// パスの置換
$paths = array_map(fn ($x) => preg_replace('/^assets\//', '[(rb_base_url)]', $x), $paths);
$paths = array_map(fn ($x) => str_replace('[(rb_base_url)]', $modx->config['rb_base_url'], $x), $paths);
$paths = array_filter(array_unique($paths));

// evo()->addLog('['.$evName.'] WebP変換', $paths);

if (count($paths) == 0) return;

// オプション
$opts = [];

if (isset($optQuality) && preg_match('/^[0-9]{1,3}$/', $optQuality)) $opts['quality'] = (int)$optQuality; // 初期値：JPEG:75、PNG:85

if (isset($optEncoding) && in_array($optEncoding, ['auto', 'lossless', 'lossy'])) $opts['png'] = [
	'encoding' => $optEncoding
]; // 初期値：auto

// WebPへ変換
foreach ($paths as $path) {
	$srcPath = (preg_match('/^(\.{1,2}\/|https?:|\/\/)/i', $path) ? '' : $basePath).$path;
	$pi      = pathinfo($srcPath);
	$outPath = $pi['dirname'].'/'.$pi['filename'].'.'.preg_replace('/^[a-z0-9]*/i', 'webp', $pi['extension']);
	$size    = preg_match('/^(https?:|\/\/)/i', $srcPath) ? ['mine' => ''] : getimagesize($srcPath);

	$result = [
		'path'      => $path,
		'srcPath'   => $srcPath,
		'mimeType'  => $size['mime'],
		'outPath'   => $outPath,
		'overwrite' => false,
		'success'   => false,
		'message'   => ''
	];

	if (preg_match('/^(https?:|\/\/)/i', $srcPath)) {
		$result['message'] = '絶対URLのためスキップしました';
		$results[] = $result;
		continue;
	} else if (!file_exists($srcPath)) {
		$result['message'] = 'ソースファイルが見つかりませんでした';
		$results[] = $result;
		continue;
	} else if (str_starts_with($pi['extension'], 'webp')) {
		$result['message'] = 'ソースファイルの形式が既にWebPです';
		$results[] = $result;
		continue;
	} else if (!isset($size['mime']) || !preg_match('/^image\/(jpeg|png)$/', $size['mime'])) {
		$result['message'] = '対応するMIMEタイプではありません';
		$results[] = $result;
		continue;
	} else if (!preg_match('/^(jpe?g|png)/i', $pi['extension'])) {
		$result['message'] = '対応する形式ではありません';
		$results[] = $result;
		continue;
	} else if (file_exists($outPath)) {
		$result['overwrite'] = true;

		if (empty($overwrite)) {
			$result['message'] = '既にWebPファイルが存在するためスキップしました';
			$results[] = $result;
			continue;
		}
	}

	// evo()->addLog('['.$evName.'] 変換情報', $result);

	WebPConvert::convert($srcPath, $outPath, $opts);

	$result['success'] = file_exists($outPath);

	$results[] = $result;
}

// evo()->addLog($ev->activePlugin, [
// 	'options' => $opts,
// 	'results' => $results
// ]);
