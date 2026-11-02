//<?php
/**
 * 拡張子をWebPへ変換
 *
 * ページ表示時に画像ファイルパスの拡張子をWebP形式に変換する
 *
 * @category    plugin
 * @version     1.0.0
 * @license    GNU General Public License (GPL), https://www.gnu.org/licenses/gpl-3.0.html
 * @author     Yu.No (https://github.com/yuno25211415)
 * @lastupdate 2026/03/22
 * @internal @events OnWebPagePrerender
 * @internal @modx_category Custom
 * @internal @installset base, sample
 * @internal @disabled 1
 */

// 出力コンテンツ
$output = &$modx->documentOutput;

// 拡張子を.webpに置換：imgタグ
$output = preg_replace_callback('/(<img[^<]*src\s*=\s*["|\'])([^"\'<]*\.)(jpe?g|png|bmp)([^"\'\.<]*?)(["|\'][^<]*?>)/i', function($matches) {
	$targetPath = $matches[2].'webp';

	if (!file_exists($targetPath)) return $matches[0];

	return $matches[1].$targetPath.$matches[4].$matches[5];
}, $output);

// 拡張子を.webpに置換：sourceタグ
$output = preg_replace_callback('/(<source[^<]*srcset\s*=\s*["|\'])([^"\'<]*\.)(jpe?g|png|bmp)([^"\'\.<]*?)(["|\'][^<]*?>)/i', function($matches) {
	$targetPath = $matches[2].'webp';

	if (!file_exists($targetPath)) return $matches[0];

	return $matches[1].$targetPath.$matches[4].$matches[5];
}, $output);
