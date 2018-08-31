function s = get_edf_filename(p)

files = shared_utils.io.dirnames( p, '.edf' );
s = sprintf( '%d.edf', numel(files)+1 );

end